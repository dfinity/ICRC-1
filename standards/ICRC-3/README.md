# `ICRC-3`: Block Log

| Status |
|:------:|
| Draft  |

`ICRC-3` is a standard for accessing the block log of a Ledger on the [Internet Computer](https://internetcomputer.org).

A Block contains a Transaction. Transactions are an enumeration of different types of operation (e.g. burn, mint, transfer, approve, ....).

`ICRC-3` specifies:
1. A generic format for sharing the block log without information loss. This includes the fields that a block must have.
2. A mechanism to verify the block log on the client side to allow downloading the block log via query calls
3. A way for new standards to define new transactions types compatible with ICRC-3
4. Two new endpoints, one to get the blocks and one to get the last block (tip) certification

## Block Log

The block log is a list of blocks where each block contains the hash of its parent (`phash`). The parent of a block `i` is block `i-1` for `i>0` and `null` for `i=0`.

```
   ┌─────────────────────────┐          ┌─────────────────────────┐
   |         Block i         |          |         Block i+1       |
   ├─────────────────────────┤          ├─────────────────────────┤
◄──| phash = hash(Block i-1) |◄─────────| phash = hash(Block i)   |
   | ...                     |          | ...                     |
   └─────────────────────────┘          └─────────────────────────┘

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

Servers must serve the block log as list of `Value` where each `Value` represent a single block in the block log.

## Value Hash

`ICRC-3` specifies a standard hash function over `Value`.

This hash function should be used by Ledgers to calculate the hash of the parent of a block and by clients to verify the downloaded block log.

The hash function is the [representation-independent hashing of structured data](https://internetcomputer.org/docs/current/references/ic-interface-spec#hash-of-map) used by the IC:
- the hash of a `Blob` is the hash of the bytes themselves
- the hash of a `Text` is the hash of the bytes representing the text
- the hash of a `Nat` is the [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128) encoding of the number
- the hash of an `Int` is the [`sleb128`](https://en.wikipedia.org/wiki/LEB128#Signed_LEB128) encoding of the number
- the hash of an `Array` is the hash of the concatenation of the hashes of all the elements of the array
- the hash of a `Map` is the hash of the concatenation of all the hashed items of the map sorted. A hashed item is the tuple composed by the hash of the key and the hash of the value.

## Blocks Verification

The Ledger MUST certify the last block (tip) recorded. The Ledger MUST allow to download the certificate via the `icrc3_get_tip_certificate` endpoint. The certificate follows the [IC Specification for Certificates](https://internetcomputer.org/docs/current/references/ic-interface-spec#certification). The certificate contains a tree with the certified data and the signature. The tree MUST contain two labelled values (leafs):
1. `last_block_index`: the index of the last block in the chain. The values must be expressed as big-endian
2. `last_block_hash`: the hash of the last block in the chain

Clients SHOULD download the tip certificate first and then download the block backward starting from `last_block_index` and validate the blocks in the process.

Validation of block `i` is done by checking the block hash against
1. if `i + 1 < len(chain)` then the parent hash `phash` of the block `i+1`
2. otherwise the `last_block_hash` in the tip certificate.

## Interaction with other standards

Each standard that adheres to `ICRC-3` must define the list of transactions types they define and/or extend together with their `Value` schema and the function that converts a [`Value`](#value) to that type. Transaction types are well-typed records that are easy to consume by clients.

`Value`s representing blocks must have the following schema properties:
1. they must be of type `Map`
1. they must have a field `tx: Map` which describes the transaction inside the block
1. they must have a field `op: Text` inside `tx` which describes the type of transactions, e.g. "ICRC1_Burn" for `ICRC1_Burn` transactions
1. all blocks with `index > 0` must have a top-level field called `phash: Blob` which contains the [hash](#value-hash) of the previous block.

In other words the schema must be:

```
type ICRC1_Block = {
    // The hash of the parent Transaction
    "phash" : Blob?;

    // The timestamp of when the block was
    // added to the Ledger
    "ts": u64,

    // The effective fee of the block. This is
    // empty if the user specified a fee in the
    // transaction tx, otherwise it contains the
    // fee
    "fee": Nat?,

    // The transaction inside the block
    "tx" : {
        "op" : Text;
        ...
    };
};
```

where the `...` in `"tx"` are the rest of the fields for the specific transaction.

For instance, [`ICRC-1`](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1) should define three transactions types - `ICRC1_Mint`, `ICRC1_Burn` and `ICRC1_Transfer` - and the function to convert a `Value` to them in order to adhere to the `ICRC-3` standard.

## Specification

### `icrc3_get_blocks`

```
type Value = variant {
    Blob : blob;
    Text : text;
    Nat : nat; // do we need this or can we just use Int?
    Int : int;
    Array : vec Value;
    Map : vec record { text; Value };
};

type GetBlocksArgs = vec record { start : nat; length : nat };

type GetBlocksResult = record {
    // Total number of blocks in the block log
    log_length : nat;

    // Blocks found locally to the Ledger
    blocks : vec record { id : nat; block: Value };

    // List of callbacks to fetch the blocks that are not local
    // to the Ledger, i.e. archived blocks
    archived_blocks : vec record {
        args : GetBlocksArgs;
        callback : func (GetTransactionsArgs) -> (GetTransactionsResult) query;
    };
};

service : {
    icrc3_get_blocks : (GetBlocksArgs) -> (GetBlocksResult) query;
};
```

### `icrc3_get_tip_certificate`

```
// See https://internetcomputer.org/docs/current/references/ic-interface-spec#certification
type DataCertificate = record {

  // Signature of the root of the hash_tree
  certificate : blob;

  // CBOR encoded hash_tree
  hash_tree : blob;
};

service : {
  icrc3_get_tip_certificate : () -> (opt DataCertificate) query;
};
```

## Transaction Types

### [ICRC-1](../ICRC-1/README.md)

#### Account Schema

Account is represented as an `Array` containing the `owner` bytes and optionally the subaccount bytes:

```
type Account = [ blob(principal); blob(subaccount)? ];
```


#### Base Operation Schema

This schema describes the common `Value` schema for all ICRC-1 operations.

```
type ICRC1_Common = {

  // The amount in the transaction
  "amt" : Nat;

  // The expected fee set by the user
  "fee" : Nat?;

  // The memo added by the user
  "memo" : Blob?;

  // The time at which the transaction
  // was created by the user. When set,
  // the Ledger must deduplicate the
  // transaction
  "ts" : u64?;
};
```

#### ICRC1_Burn Schema

```
type ICRC1_Burn = ICRC1_Common and {
  "op" : "burn";
  "from" : Account;
};
```

#### ICRC1_Mint Schema

```
type ICRC1_Mint = ICRC1_Common and {
  "op": "mint";
  "to": Account;
};
```

#### ICRC1_Transfer Schema

```
type ICRC1_Transfer = ICRC1_Common and {
  "op": "xfer";
  "from": Account;
  "to": Account;
};
```

### [ICRC-2](../ICRC-2/README.md)


#### ICRC2_Approve Schema

```
type ICRC2_Approve = ICRC1_Common and {
  "op": "approve";
  "from": Account;
  "spender": Account;
  "expected_allowance": u64?;
  "expires_at": u64?;
};
```

#### ICRC2_TransferFrom Schema

> Note: ICRC2_TransferFrom extends [ICRC1_Transfer](#icrc1_transfer-schema)

```
type ICRC2_TransferFrom = ICRC1_Transfer and {
  "spender" : Account?;
};
```