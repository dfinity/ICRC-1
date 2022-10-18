import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Error "mo:base/Error";
import Time "mo:base/Time";
import Int "mo:base/Int";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";

actor class Ledger(init : { initial_mints : [{ account : { owner : Principal; subaccount : ?Blob }; amount : Nat }]; minting_account : { owner : Principal; subaccount : ?Blob }; token_name : Text; token_symbol : Text; decimals : Nat8; transfer_fee : Nat }) = this {

  public type Account = { owner : Principal; subaccount : ?Subaccount };
  public type Subaccount = Blob;
  public type Tokens = Nat;
  public type Memo = Blob;
  public type Timestamp = Nat64;
  public type Duration = Nat64;
  public type TxIndex = Nat;
  public type TxLog = Buffer.Buffer<Transaction>;

  public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text };

  let permittedDriftNanos : Duration = 60_000_000_000;
  let transactionWindowNanos : Duration = 24 * 60 * 60 * 1_000_000_000;
  let defaultSubaccount : Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

  public type Operation = {
    #Approve : Approve;
    #Transfer : Transfer;
    #Burn : Transfer;
    #Mint : Transfer;
  };

  public type CommonFields = {
    memo : ?Memo;
    fee : ?Tokens;
    created_at_time : ?Timestamp;
  };

  public type Approve = CommonFields and {
    from : Account;
    spender : Principal;
    amount : Int;
  };

  public type Transfer = CommonFields and {
    caller : Principal;
    to : Account;
    from : Account;
    amount : Tokens;
  };

  public type TransferFrom = Transfer and {
    spender : Principal;
  };

  public type Transaction = {
    operation : Operation;
    // Effective fee for this transaction.
    fee : Tokens;
    timestamp : Timestamp;
  };

  public type DeduplicationError = {
    #TooOld;
    #Duplicate : { duplicate_of : TxIndex };
    #CreatedInFuture : { ledger_time : Timestamp };
  };

  public type CommonError = {
    #InsufficientFunds : { balance : Tokens };
    #BadFee : { expected_fee : Tokens };
    #TemporarilyUnavailable;
    #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferError = DeduplicationError or CommonError or {
    #BadBurn : { min_burn_amount : Tokens };
  };

  public type ApproveError = DeduplicationError or CommonError;

  public type TransferFromError = TransferError or {
    #InsufficientAllowance : { allowance : Nat };
  };

  public type Result<T, E> = { #Ok : T; #Err : E };

  // Checks whether two accounts are semantically equal.
  func accountsEqual(lhs : Account, rhs : Account) : Bool {
    let lhsSubaccount = Option.get(lhs.subaccount, defaultSubaccount);
    let rhsSubaccount = Option.get(rhs.subaccount, defaultSubaccount);

    Principal.equal(lhs.owner, rhs.owner) and Blob.equal(
      lhsSubaccount,
      rhsSubaccount,
    );
  };

  // Computes the balance of the specified account.
  func balance(account : Account, log : TxLog) : Nat {
    var sum = 0;
    for (tx in log.vals()) {
      switch (tx.operation) {
        case (#Burn(args)) {
          if (accountsEqual(args.from, account)) { sum -= args.amount };
        };
        case (#Mint(args)) {
          if (accountsEqual(args.to, account)) { sum += args.amount };
        };
        case (#Transfer(args)) {
          if (accountsEqual(args.from, account)) {
            sum -= args.amount + tx.fee;
          };
          if (accountsEqual(args.to, account)) { sum += args.amount };
        };
        case (#Approve(_)) {};
      };
    };
    sum;
  };

  // Computes the total token supply.
  func totalSupply(log : TxLog) : Tokens {
    var total = 0;
    for (tx in log.vals()) {
      switch (tx.operation) {
        case (#Burn(args)) { total -= args.amount };
        case (#Mint(args)) { total += args.amount };
        case (#Transfer(_)) { total -= tx.fee };
        case (#Approve(_)) {};
      };
    };
    total;
  };

  // Finds a transaction in the transaction log.
  func findTransfer(transfer : Transfer, log : TxLog) : ?TxIndex {
    var i = 0;
    for (tx in log.vals()) {
      switch (tx.operation) {
        case (#Burn(args)) { if (args == transfer) { return ?i } };
        case (#Mint(args)) { if (args == transfer) { return ?i } };
        case (#Transfer(args)) { if (args == transfer) { return ?i } };
        case (_) {};
      };
      i += 1;
    };
    null;
  };

  // Computes allowance.
  func allowance(account : Account, spender : Principal) : Nat {
    var i = 0;
    var allowance : Int = 0;
    for (tx in log.vals()) {
      switch (tx.operation) {
        case (#Approve(args)) {
          if (args.from == account and args.spender == spender) {
            allowance := Int.max(0, allowance + args.amount);
          };
        };
        case (#Transfer(args)) {
          if (args.from == account and args.caller == spender) {
            allowance -= args.amount + tx.fee;
          };
        };
        case (_) {};
      };
    };

    Int.abs(allowance);
  };

  // Checks if the principal is anonymous.
  func isAnonymous(p : Principal) : Bool {
    Blob.equal(Principal.toBlob(p), Blob.fromArray([0x04]));
  };

  // Constructs the transaction log corresponding to the init argument.
  func makeGenesisChain() : TxLog {
    validateSubaccount(init.minting_account.subaccount);

    let now = Nat64.fromNat(Int.abs(Time.now()));
    let log = Buffer.Buffer<Transaction>(100);
    for ({ account; amount } in Array.vals(init.initial_mints)) {
      validateSubaccount(account.subaccount);
      let tx : Transaction = {
        operation = #Mint({ caller = init.minting_account.owner; from = init.minting_account; to = account; amount = amount; fee = null; memo = null; created_at_time = ?now });
        fee = 0;
        timestamp = now;
      };
      log.add(tx);
    };
    log;
  };

  // Traps if the specified blob is not a valid subaccount.
  func validateSubaccount(s : ?Subaccount) {
    let subaccount = Option.get(s, defaultSubaccount);
    assert (subaccount.size() == 32);
  };

  func validateMemo(m : ?Memo) {
    switch (m) {
      case (null) {};
      case (?memo) { assert (memo.size() <= 32) };
    };
  };

  func checkTxTime(created_at_time : ?Timestamp, now : Timestamp) : Result<(), DeduplicationError> {
    let txTime : Timestamp = Option.get(created_at_time, now);

    if ((txTime > now) and (txTime - now > permittedDriftNanos)) {
      return #Err(#CreatedInFuture { ledger_time = now });
    };

    if ((txTime < now) and (now - txTime > transactionWindowNanos + permittedDriftNanos)) {
      return #Err(#TooOld);
    };

    #Ok(());
  };

  // The list of all transactions.
  var log : TxLog = makeGenesisChain();

  // The stable representation of the transaction log.
  // Used only during upgrades.
  stable var persistedLog : [Transaction] = [];

  system func preupgrade() {
    persistedLog := log.toArray();
  };

  system func postupgrade() {
    log := Buffer.Buffer(persistedLog.size());
    for (tx in Array.vals(persistedLog)) {
      log.add(tx);
    };
  };

  func recordTransaction(tx : Transaction) : TxIndex {
    let idx = log.size();
    log.add(tx);
    idx;
  };

  func classifyTransfer(transfer : Transfer) : Result<(Operation, Tokens), TransferError> {
    let minter = init.minting_account;

    let result = if (accountsEqual(transfer.from, minter)) {
      if (Option.get(transfer.fee, 0) != 0) {
        return #Err(#BadFee { expected_fee = 0 });
      };
      (#Mint(transfer), 0);
    } else if (accountsEqual(transfer.to, minter)) {
      if (Option.get(transfer.fee, 0) != 0) {
        return #Err(#BadFee { expected_fee = 0 });
      };

      if (transfer.amount < init.transfer_fee) {
        return #Err(#BadBurn { min_burn_amount = init.transfer_fee });
      };

      let debitBalance = balance(transfer.from, log);
      if (debitBalance < transfer.amount) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      (#Burn(transfer), 0);
    } else {
      let effectiveFee = init.transfer_fee;
      if (Option.get(transfer.fee, effectiveFee) != effectiveFee) {
        return #Err(#BadFee { expected_fee = init.transfer_fee });
      };

      let debitBalance = balance(transfer.from, log);
      if (debitBalance < transfer.amount + effectiveFee) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      (#Transfer(transfer), effectiveFee);
    };
    #Ok(result);
  };

  public shared ({ caller }) func icrc1_transfer({ from_subaccount : ?Subaccount; to : Account; amount : Tokens; fee : ?Tokens; memo : ?Memo; created_at_time : ?Timestamp }) : async Result<TxIndex, TransferError> {
    validateSubaccount(from_subaccount);
    validateSubaccount(to.subaccount);
    validateMemo(memo);

    let now = Nat64.fromNat(Int.abs(Time.now()));

    switch (checkTxTime(created_at_time, now)) {
      case (#Ok(_)) {};
      case (#Err(e)) { return #Err(e) };
    };

    let from = { owner = caller; subaccount = from_subaccount };

    let args : Transfer = {
      caller = caller;
      from = from;
      to = to;
      amount = amount;
      memo = memo;
      fee = fee;
      created_at_time = created_at_time;
    };

    if (Option.isSome(created_at_time)) {
      switch (findTransfer(args, log)) {
        case (?height) { return #Err(#Duplicate { duplicate_of = height }) };
        case null {};
      };
    };

    switch (classifyTransfer(args)) {
      case (#Ok((operation, effectiveFee))) {
        #Ok(recordTransaction({ operation = operation; fee = effectiveFee; timestamp = now }));
      };
      case (#Err(e)) { #Err(e) };
    };
  };

  public query func icrc1_balance_of(account : Account) : async Tokens {
    balance(account, log);
  };

  public query func icrc1_total_supply() : async Tokens {
    totalSupply(log);
  };

  public query func icrc1_minting_account() : async ?Account {
    ?init.minting_account;
  };

  public query func icrc1_name() : async Text {
    init.token_name;
  };

  public query func icrc1_symbol() : async Text {
    init.token_symbol;
  };

  public query func icrc1_decimals() : async Nat8 {
    init.decimals;
  };

  public query func icrc1_fee() : async Nat {
    init.transfer_fee;
  };

  public query func icrc1_metadata() : async [(Text, Value)] {
    [
      ("icrc1:name", #Text(init.token_name)),
      ("icrc1:symbol", #Text(init.token_symbol)),
      ("icrc1:decimals", #Nat(Nat8.toNat(init.decimals))),
      ("icrc1:fee", #Nat(init.transfer_fee)),
    ];
  };

  public query func icrc1_supported_standards() : async [{ name : Text; url : Text }] {
    [
      {
        name = "ICRC-1";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1";
      },
      {
        name = "ICRC-2";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-2";
      },
    ];
  };

  public shared ({ caller }) func icrc2_approve({ from_subaccount : ?Subaccount; spender : Principal; amount : Int; memo : ?Memo; fee : ?Tokens; created_at_time : ?Timestamp }) : async Result<TxIndex, ApproveError> {
    validateSubaccount(from_subaccount);
    validateMemo(memo);

    let now = Nat64.fromNat(Int.abs(Time.now()));

    switch (checkTxTime(created_at_time, now)) {
      case (#Ok(_)) {};
      case (#Err(e)) { return #Err(e) };
    };

    // TODO: dedup

    let effectiveFee = init.transfer_fee;

    if (Option.get(fee, effectiveFee) != effectiveFee) {
      return #Err(#BadFee({ expected_fee = effectiveFee }));
    };

    let approverAccount = { owner = caller; subaccount = from_subaccount };
    let approverBalance = balance(approverAccount, log);
    if (approverBalance < init.transfer_fee) {
      return #Err(#InsufficientFunds { balance = approverBalance });
    };

    let op = #Approve({ from = approverAccount; spender = spender; amount = amount; fee = fee; created_at_time = created_at_time; memo = memo });
    let txId = recordTransaction({ operation = op; fee = effectiveFee; timestamp = now });

    assert (balance(approverAccount, log) == approverBalance - effectiveFee);

    #Ok(txId);
  };

  public shared ({ caller }) func icrc2_transfer_from({ from : Account; to : Account; amount : Tokens; fee : ?Tokens; memo : ?Memo; created_at_time : ?Timestamp }) : async Result<TxIndex, TransferFromError> {
    validateSubaccount(from.subaccount);
    validateSubaccount(to.subaccount);
    validateMemo(memo);

    let now = Nat64.fromNat(Int.abs(Time.now()));

    switch (checkTxTime(created_at_time, now)) {
      case (#Ok(_)) {};
      case (#Err(e)) { return #Err(e) };
    };

    let transfer : Transfer = {
      caller = caller;
      from = from;
      to = to;
      amount = amount;
      fee = fee;
      memo = memo;
      created_at_time = created_at_time;
    };

    if (Option.isSome(created_at_time)) {
      switch (findTransfer(transfer, log)) {
        case (?height) { return #Err(#Duplicate { duplicate_of = height }) };
        case null {};
      };
    };

    let (operation, effectiveFee) = switch (classifyTransfer(transfer)) {
      case (#Ok(result)) { result };
      case (#Err(err)) { return #Err(err) };
    };

    // TODO: should we skip this check if caller is the account owner?

    let callerAllowance = allowance(from, caller);
    if (callerAllowance < amount + effectiveFee) {
      return #Err(#InsufficientAllowance { allowance = callerAllowance });
    };

    let txid = recordTransaction({ operation = operation; fee = effectiveFee; timestamp = now });

    assert (allowance(from, caller) == callerAllowance - amount - effectiveFee);

    #Ok(txid);
  };

  public query func icrc2_allowance({ account : Account; spender : Principal }) : async Nat {
    allowance(account, spender);
  };
};
