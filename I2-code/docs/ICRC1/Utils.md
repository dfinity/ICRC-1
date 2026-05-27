# ICRC1/Utils

## Function `init_metadata`
``` motoko no-repl
func init_metadata(args : T.InitArgs) : StableBuffer.StableBuffer<T.MetaDatum>
```


## Value `default_standard`
``` motoko no-repl
let default_standard : T.SupportedStandard
```


## Function `init_standards`
``` motoko no-repl
func init_standards() : StableBuffer.StableBuffer<T.SupportedStandard>
```


## Function `default_subaccount`
``` motoko no-repl
func default_subaccount() : T.Subaccount
```


## Function `hash`
``` motoko no-repl
func hash(n : Nat) : Hash.Hash
```


## Function `create_transfer_req`
``` motoko no-repl
func create_transfer_req(args : T.TransferArgs, owner : Principal, tx_kind : T.TxKind) : T.TransactionRequest
```


## Function `kind_to_text`
``` motoko no-repl
func kind_to_text(kind : T.TxKind) : Text
```


## Function `req_to_tx`
``` motoko no-repl
func req_to_tx(tx_req : T.TransactionRequest, index : Nat) : T.Transaction
```


## Function `div_ceil`
``` motoko no-repl
func div_ceil(n : Nat, d : Nat) : Nat
```


## Function `get_balance`
``` motoko no-repl
func get_balance(accounts : T.AccountBalances, encoded_account : T.EncodedAccount) : T.Balance
```

Retrieves the balance of an account

## Function `update_balance`
``` motoko no-repl
func update_balance(accounts : T.AccountBalances, encoded_account : T.EncodedAccount, update : (T.Balance) -> T.Balance)
```

Updates the balance of an account

## Function `transfer_balance`
``` motoko no-repl
func transfer_balance(token : T.TokenData, tx_req : T.TransactionRequest)
```


## Function `mint_balance`
``` motoko no-repl
func mint_balance(token : T.TokenData, encoded_account : T.EncodedAccount, amount : T.Balance)
```


## Function `burn_balance`
``` motoko no-repl
func burn_balance(token : T.TokenData, encoded_account : T.EncodedAccount, amount : T.Balance)
```


## Value `SB`
``` motoko no-repl
let SB
```

