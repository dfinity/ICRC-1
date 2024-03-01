# ICRC1/Canisters/Token

## Type `TokenInitArgs`
``` motoko no-repl
type TokenInitArgs = { name : Text; symbol : Text; decimals : Nat8; fee : ICRC1.Balance; max_supply : ICRC1.Balance; minting_account : ?ICRC1.Account; initial_balances : [(ICRC1.Account, ICRC1.Balance)] }
```


## `actor class Token`


### Function `icrc1_name`
``` motoko no-repl
func icrc1_name() : async Text
```

Functions for the ICRC1 token standard


### Function `icrc1_symbol`
``` motoko no-repl
func icrc1_symbol() : async Text
```



### Function `icrc1_decimals`
``` motoko no-repl
func icrc1_decimals() : async Nat8
```



### Function `icrc1_fee`
``` motoko no-repl
func icrc1_fee() : async ICRC1.Balance
```



### Function `icrc1_metadata`
``` motoko no-repl
func icrc1_metadata() : async [ICRC1.MetaDatum]
```



### Function `icrc1_total_supply`
``` motoko no-repl
func icrc1_total_supply() : async ICRC1.Balance
```



### Function `icrc1_minting_account`
``` motoko no-repl
func icrc1_minting_account() : async ?ICRC1.Account
```



### Function `icrc1_balance_of`
``` motoko no-repl
func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance
```



### Function `icrc1_supported_standards`
``` motoko no-repl
func icrc1_supported_standards() : async [ICRC1.SupportedStandard]
```



### Function `icrc1_transfer`
``` motoko no-repl
func icrc1_transfer(args : ICRC1.TransferArgs) : async Result.Result<ICRC1.Balance, ICRC1.TransferError>
```



### Function `mint`
``` motoko no-repl
func mint(args : ICRC1.Mint) : async Result.Result<ICRC1.Balance, ICRC1.TransferError>
```



### Function `burn`
``` motoko no-repl
func burn(args : ICRC1.BurnArgs) : async Result.Result<ICRC1.Balance, ICRC1.TransferError>
```



### Function `get_transaction`
``` motoko no-repl
func get_transaction(token_id : Nat) : async ?ICRC1.Transaction
```



### Function `get_transactions`
``` motoko no-repl
func get_transactions(req : ICRC1.GetTransactionsRequest) : async ()
```

