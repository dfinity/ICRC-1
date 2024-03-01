# ICRC1/Transfer

## Function `validate_memo`
``` motoko no-repl
func validate_memo(memo : ?T.Memo) : Bool
```

Checks if a transaction memo is valid

## Function `is_too_old`
``` motoko no-repl
func is_too_old(token : T.TokenData, created_at_time : Nat64) : Bool
```

Checks if the `created_at_time` of a transfer request is before the accepted time range

## Function `is_in_future`
``` motoko no-repl
func is_in_future(token : T.TokenData, created_at_time : Nat64) : Bool
```

Checks if the `created_at_time` of a transfer request has not been reached yet relative to the canister's time.

## Function `deduplicate`
``` motoko no-repl
func deduplicate(token : T.TokenData, tx_req : T.TransactionRequest) : Result.Result<(), Nat>
```

Checks if there is a duplicate transaction that matches the transfer request in the main canister.

If a duplicate is found, the function returns an error (`#err`) with the duplicate transaction's index.

## Function `validate_fee`
``` motoko no-repl
func validate_fee(token : T.TokenData, opt_fee : ?T.Balance) : Bool
```

Checks if a transfer fee is valid

## Function `validate_request`
``` motoko no-repl
func validate_request(token : T.TokenData, tx_req : T.TransactionRequest) : Result.Result<(), T.TransferError>
```

Checks if a transfer request is valid
