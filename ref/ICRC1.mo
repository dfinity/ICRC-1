import Array         "mo:base/Array";
import Blob          "mo:base/Blob";
import Buffer        "mo:base/Buffer";
import Principal     "mo:base/Principal";
import Option        "mo:base/Option";
import Error         "mo:base/Error";
import Time          "mo:base/Time";
import Int           "mo:base/Int";
import Nat8          "mo:base/Nat8";
import Nat64         "mo:base/Nat64";


actor class Ledger(init : {
                     initial_mints : [ { account : { principal : Principal; subaccount : ?Blob }; amount : Nat } ];
                     minting_account : { principal : Principal; subaccount : ?Blob };
                     token_name : Text;
                     token_symbol : Text;
                     decimals : Nat8;
                     transfer_fee : Nat;
                  }) = this {

  public type Account = { principal : Principal; subaccount : ?Subaccount };
  public type Subaccount = Blob;
  public type Tokens = Nat;
  public type Memo = Nat64;
  public type Timestamp = Nat64;
  public type Duration = Nat64;
  public type TxIndex = Nat;
  public type TxLog = Buffer.Buffer<Transaction>;

  public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text; };

  let permittedDriftNanos : Duration = 60_000_000_000;
  let transactionWindowNanos : Duration = 24 * 60 * 60 * 1_000_000_000;
  let defaultSubaccount : Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

  public type TxKind = { #Burn; #Mint; #Transfer };

  public type Transfer = {
    to : Account;
    from : Account;
    memo : ?Memo;
    amount : Tokens;
    fee : ?Tokens;
    created_at_time : ?Timestamp;
  };

  public type Transaction = {
    args : Transfer;
    kind : TxKind;
    // Effective fee for this transaction.
    fee : Tokens;
    timestamp : Timestamp;
  };

  public type TransferError = {
    #BadFee : { expected_fee : Tokens };
    #BadBurn : { min_burn_amount : Tokens };
    #InsufficientFunds : { balance : Tokens };
    #TooOld : { allowed_window_nanos : Duration };
    #CreatedInFuture;
    #Duplicate : { duplicate_of : TxIndex };
    #GenericError : { error_code : Nat; message : Text };
  };

  public type TransferResult = {
    #Ok  : TxIndex;
    #Err : TransferError;
  };

  // Checks whether two accounts are semantically equal.
  func accountsEqual(lhs : Account, rhs : Account) : Bool {
    let lhsSubaccount = Option.get(lhs.subaccount, defaultSubaccount);
    let rhsSubaccount = Option.get(rhs.subaccount, defaultSubaccount);

    Principal.equal(lhs.principal, rhs.principal) and Blob.equal(lhsSubaccount, rhsSubaccount)
  };

  // Computes the balance of the specified account.
  func balance(account : Account, log : TxLog) : Nat {
    var sum = 0;
    for (tx in log.vals()) {
      switch (tx.kind) {
        case (#Burn) {
          if (accountsEqual(tx.args.from, account)) { sum -= tx.args.amount };
        };
        case (#Mint) {
          if (accountsEqual(tx.args.to, account)) { sum += tx.args.amount };
        };
        case (#Transfer) {
          if (accountsEqual(tx.args.from, account)) { sum -= tx.args.amount + tx.fee };
          if (accountsEqual(tx.args.to, account)) { sum += tx.args.amount };
        };
      }
    };
    sum
  };

  // Computes the total token supply.
  func totalSupply(log: TxLog) : Tokens {
    var total = 0;
    for (tx in log.vals()) {
      switch (tx.kind) {
        case (#Burn) { total -= tx.args.amount };
        case (#Mint) { total += tx.args.amount };
        case (#Transfer) { total -= tx.fee };
      }
    };
    total
  };

  // Finds a transaction in the transaction log within the (now - tx_window) time frame.
  func findTransfer(transfer : Transfer, log : TxLog, now : Timestamp) : ?TxIndex {
    var i = 0;
    for (tx in log.vals()) {
      if (tx.args == transfer
          and (tx.timestamp < now + permittedDriftNanos)
          and (now - tx.timestamp) < transactionWindowNanos + permittedDriftNanos) { return ?i; };
      i += 1;
    };
    null
  };

  // Checks if the principal is anonymous.
  func isAnonymous(p : Principal) : Bool {
    Blob.equal(Principal.toBlob(p), Blob.fromArray([0x04]))
  };

  // Constructs the transaction log corresponding to the init argument.
  func makeGenesisChain() : TxLog {
    validateSubaccount(init.minting_account.subaccount);

    let now = Nat64.fromNat(Int.abs(Time.now()));
    let log = Buffer.Buffer<Transaction>(100);
    for ({account; amount} in Array.vals(init.initial_mints)) {
      validateSubaccount(account.subaccount);    
      let tx : Transaction = {
        args = {
          from = init.minting_account;
          to = account;
          amount = amount;
          fee = null;
          memo = null;
          created_at_time = ?now;
        };
        kind = #Mint;
        fee = 0;
        timestamp = now;
      };
      log.add(tx);
    };
    log
  };

  // Traps if the specified blob is not a valid subaccount.
  func validateSubaccount(s : ?Subaccount) {
    let subaccount = Option.get(s, defaultSubaccount);
    assert (subaccount.size() == 32);
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

  public shared({ caller }) func icrc1_transfer({
      from_subaccount : ?Subaccount;
      to : Account;
      amount : Tokens;
      fee : ?Tokens;
      memo : ?Memo;
      created_at_time : ?Timestamp;
  }) : async TransferResult {
    if (isAnonymous(caller)) {
      throw Error.reject("anonymous user is not allowed to transfer funds");
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));

    let txTime : Timestamp = Option.get(created_at_time, now);

    if ((txTime > now) and (txTime - now > permittedDriftNanos)) {
      return #Err(#CreatedInFuture);
    };

    if ((txTime < now) and (now - txTime > transactionWindowNanos + permittedDriftNanos)) {
      return #Err(#TooOld { allowed_window_nanos = transactionWindowNanos });
    };

    validateSubaccount(from_subaccount);
    validateSubaccount(to.subaccount);

    let from = { principal = caller; subaccount = from_subaccount };

    let args : Transfer = {
      from = from;
      to = to;
      amount = amount;
      memo = memo;
      fee = fee;
      created_at_time = created_at_time;
    };

    switch (findTransfer(args, log, now)) {
      case (?height) { return #Err(#Duplicate { duplicate_of = height }) };
      case null { };
    };

    let minter = init.minting_account;

    let (kind, effectiveFee) = if (accountsEqual(from, minter)) {
      if (Option.get(fee, 0) != 0) {
        return #Err(#BadFee { expected_fee = 0 });
      };
      (#Mint, 0)
    } else if (accountsEqual(to, minter)) {
      if (Option.get(fee, 0) != 0) {
        return #Err(#BadFee { expected_fee = 0 });
      };

      if (amount < init.transfer_fee) {
        return #Err(#BadBurn { min_burn_amount = init.transfer_fee });
      };

      let debitBalance = balance(from, log);
      if (debitBalance < amount) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      (#Burn, 0)
    } else {
      let effectiveFee = init.transfer_fee;
      if (Option.get(fee, effectiveFee) != effectiveFee) {
        return #Err(#BadFee { expected_fee = init.transfer_fee });
      };

      let debitBalance = balance(from, log);
      if (debitBalance < amount + effectiveFee) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      (#Transfer, effectiveFee)
    };

    let tx : Transaction = {
      args = args;
      kind = kind;
      fee = effectiveFee;
      timestamp = now;
    };

    let txIndex = log.size();
    log.add(tx);
    #Ok(txIndex)
  };

  public query func icrc1_balance_of(account : Account) : async Tokens {
    balance(account, log)
  };

  public query func icrc1_total_supply() : async Tokens {
    totalSupply(log)
  };

  public query func icrc1_name() : async Text {
    init.token_name
  };

  public query func icrc1_symbol() : async Text {
    init.token_symbol
  };

  public query func icrc1_decimals() : async Nat8 {
    init.decimals
  };

  public query func icrc1_metadata() : async [(Text, Value)] {
    [
      ("icrc1:name", #Text(init.token_name)),
      ("icrc1:symbol", #Text(init.token_symbol)),
      ("icrc1:decimals", #Nat(Nat8.toNat(init.decimals))),
    ]
  };

  public query func icrc1_supported_standards() : async [{ name : Text; url : Text }] {
    [
      { name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1" }
    ]
  };
}
