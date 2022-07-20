import Array         "mo:base/Array";
import List          "mo:base/List";
import Blob          "mo:base/Blob";
import Principal     "mo:base/Principal";
import Option        "mo:base/Option";
import Error         "mo:base/Error";
import Text          "mo:base/Text";
import Time          "mo:base/Time";
import Int           "mo:base/Int";
import Nat8          "mo:base/Nat8";
import Nat64         "mo:base/Nat64";


actor class Ledger(init : {
                     initial_mints : [ { account : { of : Principal; subaccount : ?Blob }; amount : Nat } ];
                     minting_account : ?{ of : Principal; subaccount : ?Blob };
                     token_name : Text;
                     token_symbol : Text;
                     decimals : Nat8;
                  }) = this {

  public type Account = { of : Principal; subaccount : ?Subaccount };
  public type Subaccount = Blob;
  public type Tokens = Nat;
  public type Memo = Nat64;
  public type Timestamp = Nat64;
  public type Duration = Nat64;
  public type BlockIndex = Nat;
  public type Blockchain = List.List<Block>;

  public type Value = { #Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text; };

  let permittedDriftNanos : Duration = 60_000_000_000;
  let transferFee : Tokens = 10_000;
  let transactionWindowNanos : Duration = 24 * 60 * 60 * 1_000_000_000;
  let defaultSubaccount : Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

  public type Operation = {
    #Burn : { from : Account; amount : Tokens; };
    #Mint : { to : Account; amount : Tokens; };
    #Transfer : { from : Account; to : Account; amount : Tokens; fee : Tokens; };
  };
  
  public type Transaction = {
    operation : Operation;
    memo : ?Memo;
    created_at_time : ?Timestamp;
  };
  
  public type Block = {
    transaction : Transaction;
    timestamp : Timestamp;
  };


  public type TransferError = {
    #BadFee : { expected_fee : Tokens };
    #BadBurn : { min_burn_amount : Tokens };
    #InsufficientFunds : { balance : Tokens };
    #TooOld : { allowed_window_nanos : Duration };
    #CreatedInFuture;
    #Duplicate : { duplicate_of : BlockIndex };
    #Generic : { error_code : Nat; message : Text };
  };
  
  public type TransferResult = {
    #Ok  : BlockIndex;
    #Err : TransferError;
  };

  func mintingAccount() : Account {
    switch (init.minting_account) {
      case (?acc) { acc };
      case null { { of = Principal.fromActor(this); subaccount = null } };
    }
  };

  func accountsEqual(lhs : Account, rhs : Account) : Bool {
    let lhsSubaccount = Option.get(lhs.subaccount, defaultSubaccount);
    let rhsSubaccount = Option.get(rhs.subaccount, defaultSubaccount);

    Principal.equal(lhs.of, rhs.of) and Blob.equal(lhsSubaccount, rhsSubaccount)
  };

  func transactionsEqual(lhs : Transaction, rhs : Transaction) : Bool {
    if (lhs.memo != rhs.memo) return false;
    if (lhs.created_at_time != rhs.created_at_time) return false;
    
    switch ((lhs.operation, rhs.operation)) {
      case (#Burn { from = lhsFrom; amount = lhsAmount; }, #Burn { from = rhsFrom; amount = rhsAmount}) {
        accountsEqual(lhsFrom, rhsFrom) and lhsAmount == rhsAmount
      };
      case (#Mint { to = lhsTo; amount = lhsAmount; }, #Mint { to = rhsTo; amount = rhsAmount }) {
        accountsEqual(lhsTo, rhsTo) and lhsAmount == rhsAmount
      };
      case (#Transfer { from = lhsFrom; to = lhsTo; amount = lhsAmount; fee = lhsFee; }, #Transfer { from = rhsFrom; to = rhsTo; amount = rhsAmount; fee = rhsFee}) {
        accountsEqual(lhsFrom, rhsFrom) and accountsEqual(lhsTo, rhsTo) and lhsAmount == rhsAmount and lhsFee == rhsFee
      };
      case _ { false };
    }
  };

  func balance(account : Account, blocks : Blockchain) : Nat {
    List.foldLeft(blocks, 0 : Nat, func(sum : Nat, block : Block) : Nat {
      switch (block.transaction.operation) {
        case (#Burn { from; amount; }) {
          if (accountsEqual(from, account)) { sum - amount } else { sum }
        };
        case (#Mint { to; amount; }) {
          if (accountsEqual(to, account)) { sum + amount } else { sum }
        };
        case (#Transfer { from; to; amount; fee; }) {
          if (accountsEqual(from, account)) { sum - amount - fee }
          else if (accountsEqual(to, account)) { sum + amount }
          else { sum }
        }
      }
    })
  };

  func findTransaction(t : Transaction, blocks : Blockchain, now : Timestamp) : ?BlockIndex {
    func go(h : BlockIndex, rest : Blockchain) : ?BlockIndex {
      switch rest {
        case null { null };
        case (?(block, tail)) {
          if (transactionsEqual(t, block.transaction)
              and (block.timestamp < now)
              and (now - block.timestamp) > transactionWindowNanos) { ?h }
          else { go(h + 1, tail) }
        };
      }
    };
    go(0, blocks)
  };

  func isAnonymous(p : Principal) : Bool {
    Blob.equal(Principal.toBlob(p), Blob.fromArray([0x04]))
  };

  func makeGenesisChain() : Blockchain {
    switch (init.minting_account) {
      case (null) {};
      case (?account) { validateSubaccount(account.subaccount) };
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));

    Array.foldLeft<{ account : Account; amount : Tokens }, Blockchain>(
        init.initial_mints,
        null,
        func(chain : Blockchain, { account: Account; amount : Tokens }) : Blockchain {
      validateSubaccount(account.subaccount);
      let block : Block = {
        transaction = {
          operation = #Mint({ to = account; amount = amount; });
          memo = null;
          created_at_time = ?now;
        };
        timestamp = now;
      };
      List.push(block, chain)
    })
  };

  func validateSubaccount(s : ?Subaccount) {
    let subaccount = Option.get(s, defaultSubaccount);
    assert (subaccount.size() == 32);
  };

  stable var blocks : Blockchain = makeGenesisChain();

  public shared({ caller }) func icrc1_transfer({
      from_subaccount : ?Subaccount;
      to_principal : Principal;
      to_subaccount : ?Subaccount;
      amount : Tokens;
      fee : ?Tokens;
      memo : ?Memo;
      created_at_time : ?Timestamp;
  }) : async TransferResult {
    if (isAnonymous(caller)) {
      throw Error.reject("anonymous user is not allowed to transfer funds");
    };

    let now = Nat64.fromNat(Int.abs(Time.now()));

    let txTime : Timestamp = switch (created_at_time) {
      case (null) { now };
      case (?ts) { ts };
    };

    if ((txTime > now) and (txTime - now > permittedDriftNanos)) {
      return #Err(#CreatedInFuture);
    };

    if ((txTime < now) and (now - txTime > transactionWindowNanos + permittedDriftNanos)) {
      return #Err(#TooOld { allowed_window_nanos = transactionWindowNanos });
    };

    validateSubaccount(from_subaccount);
    validateSubaccount(to_subaccount);

    let debitAccount = { of = caller; subaccount = from_subaccount };
    let creditAccount = { of = to_principal; subaccount = to_subaccount };

    let minter = mintingAccount();

    let operation = if (accountsEqual(debitAccount, minter)) {
      #Mint {
        to = creditAccount;
        amount = amount;
      }
    } else if (accountsEqual(creditAccount, minter)) {
      if (Option.get(fee, 0) != 0) {
        return #Err(#BadFee { expected_fee = 0 });
      };

      if (amount < transferFee) {
        throw Error.reject("Cannot BURN less than " # debug_show(transferFee));
      };

      let debitBalance = balance(debitAccount, blocks);
      if (debitBalance < amount) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      #Burn {
        from = debitAccount;
        amount = amount;
      }
    } else {
      if (Option.get(fee, transferFee) != transferFee) {
        return #Err(#BadFee { expected_fee = transferFee });
      };

      let debitBalance = balance(debitAccount, blocks);
      if (debitBalance < amount + transferFee) {
        return #Err(#InsufficientFunds { balance = debitBalance });
      };

      #Transfer {
        from = debitAccount;
        to = creditAccount;
        amount = amount;
        fee = transferFee;
      }
    };

    let transaction : Transaction = {
      operation = operation;
      memo = memo;
      created_at_time = created_at_time;
    };

    switch (findTransaction(transaction, blocks, now)) {
      case (?height) { return #Err(#Duplicate { duplicate_of = height }) };
      case null { };
    };

    let newBlock : Block = {
      transaction = transaction;
      timestamp = now;
    };

    let blockIndex = List.size(blocks);
    blocks := List.push(newBlock, blocks);
    #Ok(blockIndex)
  };

  public query func icrc1_balance_of(account : Account) : async Tokens {
    balance(account, blocks)
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
