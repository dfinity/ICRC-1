# `ICRC-3`: Transaction Log

| Status |
|:------:|
| Draft  |

`ICRC-3` is a standard for accessing the transaction log of a Ledger on the [Internet Computer](https://internetcomputer.org).

`ICRC-3` specifies:
1. A generic format for sharing the transaction log without information loss
2. A mechanism to verify the transaction log on the client side to allow downloading the transaction log via query calls
3. A way for new standards to define new transaction types compatible with ICRC-3

## Transaction Log

The transaction log is a list of transactions where each transaction contains the hash of its parent (`phash`). The parent of a transaction `i` is transaction `i-1` for `i>0` and `null` for `i=0`.

```
   ┌──────────────────────┐          ┌──────────────────────┐
   |         Tx i         |          |         Tx i+1       |
   ├──────────────────────┤          ├──────────────────────┤
◄──| phash = hash(Tx i-1) |◄─────────| phash = hash(Tx i)   |
   | ...                  |          | ...                  |
   └──────────────────────┘          └──────────────────────┘

```

## Value

The [candid](https://github.com/dfinity/candid) format supports sharing information even when the client and the server involved do not have the same schema (see the [Upgrading and subtyping](https://github.com/dfinity/candid/blob/master/spec/Candid.md#upgrading-and-subtyping) section of the candid spec). While this mechanism allows to evolve services and clients
independently without breaking them, it also means that a client may not receive all the information that the server is sending, e.g. in case the client schema lacks some fields that the server schema has.

This loss of information is not an option for `ICRC-3`. The client must receive the same exact data the server sent. For this reason, `ICRC-3` introduces the `Value` type which never changes: 

```
type Value = variant { 
    Blob : blob; 
    Text : text; 
    Nat : nat; // do we need this or can we just use Int?
    Int : int;
    Array : vec Value; 
    Map : vec record { text; Value }; 
};
```

Servers must serve the transaction log as list of `Value` where each `Value` represent a single transaction in the transaction log.

## Value Hash

`ICRC-3` specifies a standard hash function over `Value`.

This hash function should be used by Ledgers to calculate the hash of the parent of a transaction and by clients to verify the downloaded transaction log.

The hash function works is the [representation-independent hashing of structured data](https://internetcomputer.org/docs/current/references/ic-interface-spec#hash-of-map) used by the IC:
- the hash of a `Blob` is the hash of the bytes themselves
- the hash of a `Text` is the hash of the bytes representing the text
- the hash of a `Nat` is the [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128) encoding of the number
- the hash of an `Int` is the [`sleb128`](https://en.wikipedia.org/wiki/LEB128#Signed_LEB128) encoding of the number
- the hash of an `Array` is the hash of the concatenation of the hashes of all the elements of the array
- the hash of a `Map` is the hash of the concatenation of all the hashed items of the map sorted. A hashed item is the tuple composed by the hash of the key and the hash of the value.

## Interaction with other standards

Each standard that adheres to `ICRC-3` must define the list of transactions types they define and/or extend together with the function that converts a [`Value`](#value) to that type. Transaction types are well-typed records that are easy to consume by clients.

`Value`s representing transactions must have the following properties:
1. they must be of type `Map`
1. they must have a field `tx: Map` which describes the transaction
1. they must have a field `op: Text` inside `tx` which describes the type of transactions, e.g. "ICRC1_Burn" for `ICRC1_Burn` transactions
1. they must have a field `fee: opt Nat`
1. all transactions with index >0 must have a top-level field called `phash: Blob` which contains the [hash](#value-hash) of the previous transactions. 

For instance, [`ICRC-1`](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1) should define three transactions types - `ICRC1_Mint`, `ICRC1_Burn` and `ICRC1_Transfer` - and the function to convert a `Value` to them in order to adhere to the `ICRC-3` standard.

## Specification

### `icrc3_get_transactions`

```
type Value = variant { 
    Blob : blob; 
    Text : text; 
    Nat : nat; // do we need this or can we just use Int?
    Int : int;
    Array : vec Value; 
    Map : vec record { text; Value }; 
};

type GetTransactionsArgs = vec record { start : nat; length : nat };

// A function for fetching archived transactions.
type GetTransactionsFn = func (GetTransactionsArgs) -> (GetTransactionsResult) query;

type GetTransactionsResult = record {
    // Total number of transactions in the
    // transaction log
    log_length : nat;
    
    // System certificate for the hash of the
    // latest transaction in the chain.
    // Only present if `icrc3_get_transactions`
    // is called in a non-replicated query context.
    certificate : opt blob;

    transactions : vec record { id : nat; transaction: Value };

    archived_transactions : vec record {
        args : GetTransactionsArgs;
        callback : GetTransactionsFn;
    };
};

service : {
    icrc3_get_transactions : GetTransactionsFn;
};
```