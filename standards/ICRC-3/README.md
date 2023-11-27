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
    Nat : nat;
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
- the hash of a `Map` is the hash of the concatenation of all the hashed items of the map sorted lexicographically. A hashed item is the tuple composed by the hash of the key and the hash of the value.

Pseudocode for representation independent hashing of Value, together with test vectors to check compliance with the specification can be found [`here`](HASHINGVALUES.md). 

## Blocks Verification

The Ledger MUST certify the last block (tip) recorded. The Ledger MUST allow to download the certificate via the `icrc3_get_tip_certificate` endpoint. The certificate follows the [IC Specification for Certificates](https://internetcomputer.org/docs/current/references/ic-interface-spec#certification). The certificate contains a tree with the certified data and the signature. The tree MUST contain two labelled values (leafs):
1. `last_block_index`: the index of the last block in the chain. The values must be expressed as [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128)
2. `last_block_hash`: the hash of the last block in the chain

Clients SHOULD download the tip certificate first and then download the block backward starting from `last_block_index` and validate the blocks in the process.

Validation of block `i` is done by checking the block hash against
1. if `i + 1 < len(chain)` then the parent hash `phash` of the block `i+1`
2. otherwise the `last_block_hash` in the tip certificate.

## Generic Block Schema

1. it MUST be a [`Value`](#value) of variant `Map`
2. it MUST contain a field `tx: Map`
    1. `tx` MUST contain a field `op: Text`, aka operation, which uniquely describes the type of the Block. `op` values `approve`, `burn`, `mint` and `xfer` are reserved for ICRC-1 and ICRC-2 Blocks
2. it MUST contain a field `phash: Blob` which is the [hash](#value-hash) its parent if it has a parent block

## Interaction with other standards

Each standard that adheres to `ICRC-3` MUST define the list of block schemas that it introduces. Each block schema MUST:

1. extend the [Generic Block Schema](#generic-block-schema)
2. specify the expected value of `tx.op`. This MUST be unique accross all the standards. `approve`, `burn`, `mint` and `xfer` are reserved for ICRC-1 and ICRC-2

## [ICRC-1](../ICRC-1/README.md) and [ICRC-2](../ICRC-2/README.md) Block Schema

ICRC-1 and ICRC-2 use the `tx` field to store input from the user and use the external block to store data set by the Ledger. For instance, the amount of a transaction is stored in the field `tx.amt` because it has been specified by the user, while the time when the block was added to the Ledger is stored in the field `ts` because it is set by the Ledger.

A generic ICRC-1 or ICRC-2 Block:

1. it MUST contain a field `ts: u64` which is the timestamp of when the block was added to the Ledger
2. if the `tx` field doesn't specify the fee then it MUST contain a field `fee: Nat` which specifies the fee payed to add this block to the Ledger
3. its field `tx`
    1. MUST contain a field `amt: Nat` that represents the amount
    2. MUST contain the `fee: Nat` if the top-level `fee` is not set which is when the user didn't specify the expected `fee`
    3. CAN contain the `memo: Blob` field if specified by the user
    4. CAN contain the `ts: u64` field if specified by the user

### Account Type

ICRC-1 Account is represented as an `Array` containing the `owner` bytes and optionally the subaccount bytes.

### Burn Block Schema

1. the `tx.op` field MUST be `"burn"`
2. it MUST contain a field `tx.from: Account`

#### Mint Block Schema

1. the `tx.op` field MUST be `"mint"`
2. it MUST contain a field `tx.to: Account`

#### Transfer Block Schema

1. the `tx.op` field MUST be `"xfer"`
2. it MUST contain a field `tx.from: Account`
3. it MUST contain a field `tx.to: Account`
4. it CAN contain a field `tx.spender: Account`

#### Approve Block Schema

1. the `tx.op` field MUST be `"approve"`
2. it MUST contain a field `tx.from: Account`
3. it MUST contain a field `tx.spender: Account`
4. it CAN contain a field `tx.expected_allowance: u64` if set by the user
5. it CAN contain a field `tx.expires_at: u64` if set by the user

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