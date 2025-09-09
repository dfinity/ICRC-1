# ICRC1/lib

## Type `Account`
``` motoko no-repl
type Account = T.Account
```


## Type `Subaccount`
``` motoko no-repl
type Subaccount = T.Subaccount
```


## Type `AccountBalances`
``` motoko no-repl
type AccountBalances = T.AccountBalances
```


## Type `Transaction`
``` motoko no-repl
type Transaction = T.Transaction
```


## Type `Balance`
``` motoko no-repl
type Balance = T.Balance
```


## Type `TransferArgs`
``` motoko no-repl
type TransferArgs = T.TransferArgs
```


## Type `Mint`
``` motoko no-repl
type Mint = T.Mint
```


## Type `BurnArgs`
``` motoko no-repl
type BurnArgs = T.BurnArgs
```


## Type `TransactionRequest`
``` motoko no-repl
type TransactionRequest = T.TransactionRequest
```


## Type `TransferError`
``` motoko no-repl
type TransferError = T.TransferError
```


## Type `SupportedStandard`
``` motoko no-repl
type SupportedStandard = T.SupportedStandard
```


## Type `InitArgs`
``` motoko no-repl
type InitArgs = T.InitArgs
```


## Type `TokenInitArgs`
``` motoko no-repl
type TokenInitArgs = T.TokenInitArgs
```


## Type `TokenData`
``` motoko no-repl
type TokenData = T.TokenData
```


## Type `MetaDatum`
``` motoko no-repl
type MetaDatum = T.MetaDatum
```


## Type `TxLog`
``` motoko no-repl
type TxLog = T.TxLog
```


## Type `TxIndex`
``` motoko no-repl
type TxIndex = T.TxIndex
```


## Type `TokenInterface`
``` motoko no-repl
type TokenInterface = T.TokenInterface
```


## Type `RosettaInterface`
``` motoko no-repl
type RosettaInterface = T.RosettaInterface
```


## Type `FullInterface`
``` motoko no-repl
type FullInterface = T.FullInterface
```


## Type `ArchiveInterface`
``` motoko no-repl
type ArchiveInterface = T.ArchiveInterface
```


## Type `GetTransactionsRequest`
``` motoko no-repl
type GetTransactionsRequest = T.GetTransactionsRequest
```


## Type `GetTransactionsResponse`
``` motoko no-repl
type GetTransactionsResponse = T.GetTransactionsResponse
```


## Type `QueryArchiveFn`
``` motoko no-repl
type QueryArchiveFn = T.QueryArchiveFn
```


## Type `TransactionRange`
``` motoko no-repl
type TransactionRange = T.TransactionRange
```


## Type `ArchivedTransaction`
``` motoko no-repl
type ArchivedTransaction = T.ArchivedTransaction
```


## Type `TransferResult`
``` motoko no-repl
type TransferResult = T.TransferResult
```


## Value `MAX_TRANSACTIONS_IN_LEDGER`
``` motoko no-repl
let MAX_TRANSACTIONS_IN_LEDGER
```


## Value `MAX_TRANSACTION_BYTES`
``` motoko no-repl
let MAX_TRANSACTION_BYTES : Nat64
```


## Value `MAX_TRANSACTIONS_PER_REQUEST`
``` motoko no-repl
let MAX_TRANSACTIONS_PER_REQUEST
```


## Function `init`
``` motoko no-repl
func init(args : T.InitArgs) : T.TokenData
```

Initialize a new ICRC-1 token

## Function `name`
``` motoko no-repl
func name(token : T.TokenData) : Text
```

Retrieve the name of the token

## Function `symbol`
``` motoko no-repl
func symbol(token : T.TokenData) : Text
```

Retrieve the symbol of the token

## Function `decimals`
``` motoko no-repl
func decimals() : Nat8
```

Retrieve the number of decimals specified for the token

## Function `fee`
``` motoko no-repl
func fee(token : T.TokenData) : T.Balance
```

Retrieve the fee for each transfer

## Function `set_fee`
``` motoko no-repl
func set_fee(token : T.TokenData, fee : Nat)
```

Set the fee for each transfer

## Function `metadata`
``` motoko no-repl
func metadata(token : T.TokenData) : [T.MetaDatum]
```

Retrieve all the metadata of the token

## Function `total_supply`
``` motoko no-repl
func total_supply(token : T.TokenData) : T.Balance
```

Returns the total supply of circulating tokens

## Function `minted_supply`
``` motoko no-repl
func minted_supply(token : T.TokenData) : T.Balance
```

Returns the total supply of minted tokens

## Function `burned_supply`
``` motoko no-repl
func burned_supply(token : T.TokenData) : T.Balance
```

Returns the total supply of burned tokens

## Function `max_supply`
``` motoko no-repl
func max_supply(token : T.TokenData) : T.Balance
```

Returns the maximum supply of tokens

## Function `minting_account`
``` motoko no-repl
func minting_account(token : T.TokenData) : T.Account
```

Returns the account with the permission to mint tokens

Note: **The minting account can only participate in minting
and burning transactions, so any tokens sent to it will be
considered burned.**

## Function `balance_of`
``` motoko no-repl
func balance_of(account : T.Account) : T.Balance
```

Retrieve the balance of a given account

## Function `supported_standards`
``` motoko no-repl
func supported_standards(token : T.TokenData) : [T.SupportedStandard]
```

Returns an array of standards supported by this token

## Function `balance_from_float`
``` motoko no-repl
func balance_from_float(token : T.TokenData, float : Float) : T.Balance
```

Formats a float to a nat balance and applies the correct number of decimal places

## Function `transfer`
``` motoko no-repl
func transfer(token : T.TokenData, args : T.TransferArgs, caller : Principal) : async T.TransferResult
```

Transfers tokens from one account to another account (minting and burning included)

## Function `mint`
``` motoko no-repl
func mint(token : T.TokenData, args : T.Mint, caller : Principal) : async T.TransferResult
```

Helper function to mint tokens with minimum args

## Function `burn`
``` motoko no-repl
func burn(token : T.TokenData, args : T.BurnArgs, caller : Principal) : async T.TransferResult
```

Helper function to burn tokens with minimum args

## Function `total_transactions`
``` motoko no-repl
func total_transactions(token : T.TokenData) : Nat
```

Returns the total number of transactions that have been processed by the given token.

## Function `get_transaction`
``` motoko no-repl
func get_transaction(token : T.TokenData, tx_index : T.TxIndex) : async ?T.Transaction
```

Retrieves the transaction specified by the given `tx_index`

## Function `get_transactions`
``` motoko no-repl
func get_transactions(token : T.TokenData, req : T.GetTransactionsRequest) : T.GetTransactionsResponse
```

Retrieves the transactions specified by the given range
