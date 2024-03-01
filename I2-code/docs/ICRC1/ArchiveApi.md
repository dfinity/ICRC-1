# ICRC1/ArchiveApi

## Function `create_canister`
``` motoko no-repl
func create_canister() : async T.ArchiveInterface
```

creates a new archive canister

## Function `total_txs`
``` motoko no-repl
func total_txs(archives : T.StableBuffer<T.ArchiveData>) : Nat
```

Get the total number of archived transactions

## Function `append_transactions`
``` motoko no-repl
func append_transactions(token : T.TokenData) : async ()
```

Moves the transactions from the ICRC1 canister to the archive canister
and returns a boolean that indicates the success of the data transfer
