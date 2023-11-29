# `ICRC-3`: Block Log

| Status |
|:------:|
| Draft  |

`ICRC-3` is a standard for accessing the block log of a Ledger on the [Internet Computer](https://internetcomputer.org).

A Block contains a Transaction. Transactions are an enumeration of different types of operation (e.g. burn, mint, transfer, approve, ....).

`ICRC-3` specifies:
1. A generic format for sharing the block log without information loss. This includes the fields that a block must have
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

This loss of information is not an option for `ICRC-3`. The client must receive the same exact data the server sent in order to verify it. Verification is done by hashing the data and checking that the result is consistent with what has been certified by the server.

For this reason, `ICRC-3` introduces the `Value` type which never changes:

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

Servers must serve the block log as a list of `Value` where each `Value` represent a single block in the block log.

## Value Hash

`ICRC-3` specifies a standard hash function over `Value`.

This hash function should be used by Ledgers to calculate the hash of the parent of a block and by clients to verify the downloaded block log.

The hash function is the [representation-independent hashing of structured data](https://internetcomputer.org/docs/current/references/ic-interface-spec#hash-of-map) used by the IC:
- the hash of a `Blob` is the hash of the bytes themselves
- the hash of a `Text` is the hash of the bytes representing the text
- the hash of a `Nat` is the hash of the [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128) encoding of the number
- the hash of an `Int` is the hash of the [`sleb128`](https://en.wikipedia.org/wiki/LEB128#Signed_LEB128) encoding of the number
- the hash of an `Array` is the hash of the concatenation of the hashes of all the elements of the array
- the hash of a `Map` is the hash of the concatenation of all the hashed items of the map sorted lexicographically. A hashed item is the tuple composed by the hash of the key and the hash of the value.

Pseudocode for representation independent hashing of Value, together with test vectors to check compliance with the specification can be found [`here`](HASHINGVALUES.md). 

## Blocks Verification

The Ledger MUST certify the last block (tip) recorded. The Ledger MUST allow to download the certificate via the `icrc3_get_tip_certificate` endpoint. The certificate follows the [IC Specification for Certificates](https://internetcomputer.org/docs/current/references/ic-interface-spec#certification). The certificate is comprised of a tree containing the certified data and the signature. The tree MUST contain two labelled values (leafs):
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
2. it MUST contain a field `phash: Blob` which is the [hash](#value-hash) of its parent if it has a parent block

## Interaction with other standards

Each standard that adheres to `ICRC-3` MUST define the list of block schemas that it introduces. Each block schema MUST:

1. extend the [Generic Block Schema](#generic-block-schema)
2. specify the expected value of `tx.op`. This MUST be unique accross all the standards. `approve`, `burn`, `mint` and `xfer` are reserved for ICRC-1 and ICRC-2. An ICRC-x standard MUST use namespacing for its op identifiers using the scheme:
```
op = icrc_number op_name
icrc_number = nonzero_digit *digit
nonzero digit = "1" "2" "3" "4" "5" "6" "7" "8" "9"
digit = "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
op_name = a-z *(alphanumeric \ "_" \ "-")
```

## [ICRC-1](../ICRC-1/README.md) and [ICRC-2](../ICRC-2/README.md) Block Schema

ICRC-1 and ICRC-2 use the `tx` field to store input from the user and use the external block to store data set by the Ledger. For instance, the amount of a transaction is stored in the field `tx.amt` because it has been specified by the user, while the time when the block was added to the Ledger is stored in the field `ts` because it is set by the Ledger.

A generic ICRC-1 or ICRC-2 Block:

1. it MUST contain a field `ts: Nat` which is the timestamp of when the block was added to the Ledger
2. if the operation requires a fee and if the `tx` field doesn't specify the fee then it MUST contain a field `fee: Nat` which specifies the fee payed to add this block to the Ledger
3. its field `tx`
    1. MUST contain a field `amt: Nat` that represents the amount
    2. MUST contain the `fee: Nat` field for operations that require a fee if the user specifies the fee in the request. If the user does not specify the fee in the request, then this field is not set and the top-level `fee` is set.
    3. CAN contain the `memo: Blob` field if specified by the user
    4. CAN contain the `ts: Nat` field if the user sets the `created_at_time` field in the request.

Operations that require paying a fee: Transfer, and Approve. 

### Account Type

ICRC-1 Account is represented as an `Array` containing the `owner` bytes and optionally the subaccount bytes.

### Burn Block Schema

1. the `tx.op` field MUST be `"burn"`
2. it MUST contain a field `tx.from: Account`

Example:
```
variant { Map = vec {
    record { "phash"; variant {
        Blob = blob "\a1\a9p\f5\17\e5\e2\92\87\96(\c8\f1\88iM\0d(tN\f4-~u\19\88\83\d8_\b2\01\ec"
    }};
    record { "ts"; variant { Nat = 1_701_108_969_851_098_255 : nat }};
    record { "tx"; variant { Map = vec {
        record { "op"; variant { Text = "burn" } };
        record { "amt"; variant { Nat = 1_228_990 : nat } };
        record { "from"; variant { Array = vec {
                variant { Blob = blob "\00\00\00\00\020\00\07\01\01" };
                variant { Blob = blob "&\99\c0H\7f\a4\a5Q\af\c7\f4;\d9\e9\ca\e5 \e3\94\84\b5c\b6\97/\00\e6\a0\e9\d3p\1a" };
        }}};
        record { "memo"; variant { Blob = blob "\82\00\83x\223K7Bg3LUkiXZ5hatPT1b9h3XxJ89DYSU2e\19\07\d0\00"
        }};
    }}};
}};
```

#### Mint Block Schema

1. the `tx.op` field MUST be `"mint"`
2. it MUST contain a field `tx.to: Account`

Example:
```
variant { Map = vec {
    record { "ts"; variant { Nat = 1_675_241_149_669_614_928 : nat } };
    record { "tx"; variant { Map = vec {
        record { "op"; variant { Text = "mint" } };
        record { "amt"; variant { Nat = 100_000 : nat } };
        record { "to"; variant { Array = vec {
                variant { Blob = blob "Z\d0\ea\e8;\04*\c2CY\8b\delN\ea>]\ff\12^. WGj0\10\e4\02" };
        }}};
    }}};
}};
```

#### Transfer Block Schema

1. the `tx.op` field MUST be `"xfer"`
2. it MUST contain a field `tx.from: Account`
3. it MUST contain a field `tx.to: Account`
4. it CAN contain a field `tx.spender: Account`

Example:
```
variant { Map = vec {
    record { "fee"; variant { Nat = 10 : nat } };
    record { "phash"; variant { Blob =
        blob "h,,\97\82\ff.\9cx&l\a2e\e7KFVv\d1\89\beJ\c5\c5\ad,h\5c<\ca\ce\be"
    }};
    record { "ts"; variant { Nat = 1_701_109_006_692_276_133 : nat } };
    record { "tx"; variant { Map = vec {
        record { "op"; variant { Text = "xfer" } };
        record { "amt"; variant { Nat = 609_618 : nat } };
        record { "from"; variant { Array = vec {
                variant { Blob = blob "\00\00\00\00\00\f0\13x\01\01" };
                variant { Blob = blob "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" };
        }}};
        record { "to"; variant { Array = vec {
            variant { Blob = blob " \ef\1f\83Zs\0a?\dc\d5y\e7\ccS\9f\0b\14a\ac\9f\fb\f0bf\f3\a9\c7D\02" };
            variant { Blob = blob "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" };
        }}};
    }}};
}};
```

#### Approve Block Schema

1. the `tx.op` field MUST be `"approve"`
2. it MUST contain a field `tx.from: Account`
3. it MUST contain a field `tx.spender: Account`
4. it CAN contain a field `tx.expected_allowance: Nat` if set by the user
5. it CAN contain a field `tx.expires_at: Nat` if set by the user

Example:
```
variant { Map = vec {
    record { "fee"; variant { Nat = 10 : nat } };
    record { "phash"; variant {
        Blob = blob ";\f7\bet\b6\90\b7\ea2\f4\98\a5\b0\60\a5li3\dcXN\1f##2\b5\db\de\b1\b3\02\f5"
    }};
    record { "ts"; variant { Nat = 1_701_167_840_950_358_788 : nat } };
    record { "tx"; variant { Map = vec {
        record { "op"; variant { Text = "approve" } };
        record { "amt"; variant { Nat = 18_446_744_073_709_551_615 : nat } };
        record { "from"; variant { Array = vec {
                variant { Blob = blob "\16c\e1\91v\eb\e5)\84:\b2\80\13\cc\09\02\01\a8\03[X\a5\a0\d3\1f\e4\c3{\02" };
        }}};
        record { "spender"; variant { Array = vec {
            variant { Blob = blob "\00\00\00\00\00\e0\1dI\01\01" };
        }}};
    }}};
}}};
```

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

type GetArchivesArgs = record {
    // The last archive seen by the client.
    // The Ledger will return archives coming
    // after this one if set, otherwise it
    // will return the first archives.
    from : opt principal;
};

type GetArchivesResult = vec {
    // The id of the archive
    canister_id : principal;

    // The first block in the archive
    start : nat;

    // The last block in the archive
    end : nat;
}

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
        callback : func (GetBlocksArgs) -> (GetBlocksResult) query;
    };
};

service : {
    icrc3_get_archives : (GetArchivesArgs) -> (GetArchivesResult) query;
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