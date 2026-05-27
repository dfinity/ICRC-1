# ICRC1/Types

## Type `Value`
``` motoko no-repl
type Value = {#Nat : Nat; #Int : Int; #Blob : Blob; #Text : Text}
```


## Type `BlockIndex`
``` motoko no-repl
type BlockIndex = Nat
```


## Type `Subaccount`
``` motoko no-repl
type Subaccount = Blob
```


## Type `Balance`
``` motoko no-repl
type Balance = Nat
```


## Type `StableBuffer`
``` motoko no-repl
type StableBuffer<T> = StableBuffer.StableBuffer<T>
```


## Type `StableTrieMap`
``` motoko no-repl
type StableTrieMap<K, V> = STMap.StableTrieMap<K, V>
```


## Type `Account`
``` motoko no-repl
type Account = { owner : Principal; subaccount : ?Subaccount }
```


## Type `EncodedAccount`
``` motoko no-repl
type EncodedAccount = Blob
```


## Type `SupportedStandard`
``` motoko no-repl
type SupportedStandard = { name : Text; url : Text }
```


## Type `Memo`
``` motoko no-repl
type Memo = Blob
```


## Type `Timestamp`
``` motoko no-repl
type Timestamp = Nat64
```


## Type `Duration`
``` motoko no-repl
type Duration = Nat64
```


## Type `TxIndex`
``` motoko no-repl
type TxIndex = Nat
```


## Type `TxLog`
``` motoko no-repl
type TxLog = StableBuffer<Transaction>
```


## Type `MetaDatum`
``` motoko no-repl
type MetaDatum = (Text, Value)
```


## Type `MetaData`
``` motoko no-repl
type MetaData = [MetaDatum]
```


## Type `TxKind`
``` motoko no-repl
type TxKind = {#mint; #burn; #transfer}
```


## Type `Mint`
``` motoko no-repl
type Mint = { to : Account; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `BurnArgs`
``` motoko no-repl
type BurnArgs = { from_subaccount : ?Subaccount; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `Burn`
``` motoko no-repl
type Burn = { from : Account; amount : Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `TransferArgs`
``` motoko no-repl
type TransferArgs = { from_subaccount : ?Subaccount; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64 }
```

Arguments for a transfer operation

## Type `Transfer`
``` motoko no-repl
type Transfer = { from : Account; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64 }
```


## Type `TransactionRequest`
``` motoko no-repl
type TransactionRequest = { kind : TxKind; from : Account; to : Account; amount : Balance; fee : ?Balance; memo : ?Blob; created_at_time : ?Nat64; encoded : { from : EncodedAccount; to : EncodedAccount } }
```

Internal representation of a transaction request

## Type `Transaction`
``` motoko no-repl
type Transaction = { kind : Text; mint : ?Mint; burn : ?Burn; transfer : ?Transfer; index : TxIndex; timestamp : Timestamp }
```


## Type `TimeError`
``` motoko no-repl
type TimeError = {#TooOld; #CreatedInFuture : { ledger_time : Timestamp }}
```


## Type `TransferError`
``` motoko no-repl
type TransferError = TimeError or {#BadFee : { expected_fee : Balance }; #BadBurn : { min_burn_amount : Balance }; #InsufficientFunds : { balance : Balance }; #Duplicate : { duplicate_of : TxIndex }; #TemporarilyUnavailable; #GenericError : { error_code : Nat; message : Text }}
```


## Type `TransferResult`
``` motoko no-repl
type TransferResult = {#Ok : TxIndex; #Err : TransferError}
```


## Type `TokenInterface`
``` motoko no-repl
type TokenInterface = actor { icrc1_name : shared query () -> async Text; icrc1_symbol : shared query () -> async Text; icrc1_decimals : shared query () -> async Nat8; icrc1_fee : shared query () -> async Balance; icrc1_metadata : shared query () -> async MetaData; icrc1_total_supply : shared query () -> async Balance; icrc1_minting_account : shared query () -> async ?Account; icrc1_balance_of : shared query (Account) -> async Balance; icrc1_transfer : shared (TransferArgs) -> async TransferResult; icrc1_supported_standards : shared query () -> async [SupportedStandard] }
```

Interface for the ICRC token canister

## Type `TxCandidBlob`
``` motoko no-repl
type TxCandidBlob = Blob
```


## Type `ArchiveInterface`
``` motoko no-repl
type ArchiveInterface = actor { append_transactions : shared ([Transaction]) -> async Result.Result<(), Text>; total_transactions : shared query () -> async Nat; get_transaction : shared query (TxIndex) -> async ?Transaction; get_transactions : shared query (GetTransactionsRequest) -> async TransactionRange; remaining_capacity : shared query () -> async Nat }
```

The Interface for the Archive canister

## Type `InitArgs`
``` motoko no-repl
type InitArgs = { name : Text; symbol : Text; decimals : Nat8; fee : Balance; minting_account : Account; max_supply : Balance; initial_balances : [(Account, Balance)]; min_burn_amount : Balance; advanced_settings : ?AdvancedSettings }
```

Initial arguments for the setting up the icrc1 token canister

## Type `TokenInitArgs`
``` motoko no-repl
type TokenInitArgs = { name : Text; symbol : Text; decimals : Nat8; fee : Balance; max_supply : Balance; initial_balances : [(Account, Balance)]; min_burn_amount : Balance; minting_account : ?Account; advanced_settings : ?AdvancedSettings }
```

[InitArgs](#type.InitArgs) with optional fields for initializing a token canister

## Type `AdvancedSettings`
``` motoko no-repl
type AdvancedSettings = { burned_tokens : Balance; transaction_window : Timestamp; permitted_drift : Timestamp }
```

Additional settings for the [InitArgs](#type.InitArgs) type during initialization of an icrc1 token canister

## Type `AccountBalances`
``` motoko no-repl
type AccountBalances = StableTrieMap<EncodedAccount, Balance>
```


## Type `ArchiveData`
``` motoko no-repl
type ArchiveData = { var canister : ArchiveInterface; var stored_txs : Nat }
```

The details of the archive canister

## Type `TokenData`
``` motoko no-repl
type TokenData = { name : Text; symbol : Text; decimals : Nat8; var _fee : Balance; max_supply : Balance; var _minted_tokens : Balance; var _burned_tokens : Balance; minting_account : Account; accounts : AccountBalances; metadata : StableBuffer<MetaDatum>; supported_standards : StableBuffer<SupportedStandard>; transaction_window : Nat; min_burn_amount : Balance; permitted_drift : Nat; transactions : StableBuffer<Transaction>; archive : ArchiveData }
```

The state of the token canister

## Type `GetTransactionsRequest`
``` motoko no-repl
type GetTransactionsRequest = { start : TxIndex; length : Nat }
```

The type to request a range of transactions from the ledger canister

## Type `TransactionRange`
``` motoko no-repl
type TransactionRange = { transactions : [Transaction] }
```


## Type `QueryArchiveFn`
``` motoko no-repl
type QueryArchiveFn = shared query (GetTransactionsRequest) -> async TransactionRange
```


## Type `ArchivedTransaction`
``` motoko no-repl
type ArchivedTransaction = { start : TxIndex; length : Nat; callback : QueryArchiveFn }
```


## Type `GetTransactionsResponse`
``` motoko no-repl
type GetTransactionsResponse = { log_length : Nat; first_index : TxIndex; transactions : [Transaction]; archived_transactions : [ArchivedTransaction] }
```


## Type `RosettaInterface`
``` motoko no-repl
type RosettaInterface = actor { get_transactions : shared query (GetTransactionsRequest) -> async GetTransactionsResponse }
```

Functions supported by the rosetta 

## Type `FullInterface`
``` motoko no-repl
type FullInterface = TokenInterface and RosettaInterface
```

Interface of the ICRC token and Rosetta canister
