# `ICRC-3`: Block Log

| Status |
|:------:|
| [Accepted](https://dashboard.internetcomputer.org/proposal/128824)  |

`ICRC-3` is a standard for accessing the block log of a Ledger on the [Internet Computer](https://internetcomputer.org).

`ICRC-3` specifies:
1. A way to fetch the archive nodes of a Ledger
2. A generic format for sharing the block log without information loss. This includes the fields that a block must have
3. A mechanism to verify the block log on the client side to allow downloading the block log via query calls
4. A way for new standards to define new transactions types compatible with ICRC-3

## Archive Nodes

The Ledger must expose an endpoint `icrc3_get_archives` listing all the canisters containing its blocks.

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

An ICRC-3 compliant Block

1. MUST be a `Value` of variant `Map`
2. MUST contain a field `phash: Blob` which is the hash of its parent if it has a parent block
3. SHOULD contain a field `btype: String` which uniquely describes the type of the Block. If this field is not set then the block type falls back to ICRC-1 and ICRC-2 for backward compatibility purposes

## Interaction with other standards

Each standard that adheres to `ICRC-3` MUST define the list of block schemas that it introduces. Each block schema MUST:

1. extend the [Generic Block Schema](#generic-block-schema)
2. specify the expected value of `btype`. This MUST be unique accross all the standards. An ICRC-x standard MUST use namespacing for its op identifiers using the following scheme of using the ICRC standard's number as prefix to the name followed by an operation name that must begin with a letter:

```
op = icrc_number op_name
icrc_number = nonzero_digit *digit
nonzero_digit = "1" / "2" / "3" / "4" / "5" / "6" / "7" / "8" / "9"
digit = "0" / nonzero_digit
op_name = a-z *(a-z / digit / "_" / "-")
```


## Supported Standards

An ICRC-3 compatible Ledger MUST expose an endpoint listing all the supported block types via the endpoint `icrc3_supported_block_types`. The Ledger MUST return only blocks with `btype` set to one of the values returned by this endpoint.

## [ICRC-1](../ICRC-1/README.md) and [ICRC-2](../ICRC-2/README.md) Block Schema

This section describes how ICRC-1 and ICRC-2 operations are recorded in ICRC-3-compliant blocks.



### No `btype` Field
ICRC-1 and ICRC-2 blocks MUST NOT include a `btype` field. These standards use the legacy block format where the type of block is determined exclusively by the content of the `tx` field. ICRC-1 and ICRC-2 blocks use the `tx` field to store input from the user and use the external block to store data set by the Ledger. For instance, the amount of a transaction is stored in the field `tx.amt` because it has been specified by the user, while the time when the block was added to the Ledger is stored in the field `ts` because it is set by the Ledger.

#### Block Structure 

A generic ICRC-1 or ICRC-2 Block:

- **MUST** use the legacy format, i.e., it **MUST NOT** include a `"btype"` field.
- **MUST** be a `Value::Map` containing at least the following fields:
  - `"phash"`: `Blob` — the hash of the parent block.
  - `"ts"`: `Nat` — the timestamp (set by the ledger at block creation).
  - `"tx"`: `Value::Map` — representing the user’s transaction intent.
- **CAN** include:
  - `"fee"`: `Nat` — only if the ledger requires a fee and the user did not specify one in `tx.fee`.


#### `tx` Field Semantics

The `tx` field:

- **MUST** represent the user intent derived from the method call.
- **MUST** be encoded using the ICRC-3 `Value` type.
- **MUST NOT** contain any fields that were not explicitly present in the original user call.
- **MUST** follow the canonical mapping rules described in the next section.
- **MUST** contain a field `op: String` with value one of "mint", "burn", "xfer", "approve"
- **MUST** contain a field `amt: Nat` that represents the amount
- **MUST**  contain the `fee: Nat` field for operations that require a fee if the user specifies the fee in the request. If the user does not specify the fee in the request, then this field is not set and the top-level `fee` is set.
 - **CAN**  contain the `memo: Blob` field if specified by the user
 - **CAN** contain the `ts: Nat` field if the user sets the `created_at_time` field in the request.


Operations that require paying a fee: Transfer, and Approve.

### Compliance Reporting

Although legacy ICRC-1 and ICRC-2 blocks do not include the `btype` field, ledgers **MUST** still report their supported block types via the `icrc3_supported_block_types` endpoint. By convention, the following identifiers are used to describe the types of these legacy blocks:

- `"1burn"` for burn blocks
- `"1mint"` for mint blocks
- `"1xfer"` for `icrc1_transfer` blocks
- `"2xfer"` for `icrc2_transfer_from` blocks
- `"2approve"` for `icrc2_approve` blocks


### Account Type

ICRC-1 Account is represented as an `Array` containing the `owner` bytes and optionally the subaccount bytes.  Two examples of accounts, one with subaccount and the second without are below. 

Example of account representation as an array with two blobs, one for the owner principal and the second for the subaccount:

```
variant { Array = vec {
                variant { Blob = blob "\00\00\00\00\00\f0\13x\01\01" };
                variant { Blob = blob "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00" };
        }};
```


Example of account representation as an array with one blob encoding the owner principal.
```
variant { Array = vec {
                variant { Blob = blob "\00\00\00\00\00\f0\13x\01\01" };
            
        }};
```


### Canonical `tx` Mapping

Each ICRC-1 or ICRC-2 method call maps deterministically to the `tx` field of the resulting block. Only parameters provided by the user are included — optional fields that are omitted in the call MUST NOT appear in `tx`.

All fields are encoded using the ICRC-3 `Value` type.

---

#### `icrc1_transfer`

**Call parameters:**

```candid
icrc1_transfer: record {
  to: Account;
  amount: Nat;
  fee: opt Nat;
  memo: opt Blob;
  from_subaccount: opt blob;
  created_at_time: opt Nat;
}
```

**Regular Transfer** — when neither the sender nor recipient is the minting account:

- `op = "xfer"`
- `from = [caller]` if `from_subaccount` is not provided  
- `from = [caller, from_subaccount]` if provided
- `to = to`
- `amt = amount`
- `fee = fee` if provided
- `memo = memo` if provided
- `ts = created_at_time` if provided




**Transfer from the Minting Account (→ Mint)** — when `[caller]` or `[caller, from_subaccount]` equals the minting account:

- `op = "mint"`
- `to = to`
- `amt = amount`
- `memo = memo` if provided
- `ts = created_at_time` if provided  
> `from` and `fee` MUST NOT be present

**Transfer to the Minting Account (→ Burn)** — when `to` equals the minting account:

- `op = "burn"`
- `from = [caller]` if `from_subaccount` is not provided  
- `from = [caller, from_subaccount]` if provided
- `amt = amount`
- `memo = memo` if provided
- `ts = created_at_time` if provided  
> `to` and `fee` MUST NOT be present


### Canonical Examples of `icrc1_transfer` Blocks

Each of the following examples represents a canonical block resulting from an `icrc1_transfer` call. These examples illustrate different scenarios depending on which optional fields were included in the call. Only parameters explicitly provided by the caller appear in the resulting `tx`.

---

#### Example 1: Transfer with required parameters only
This example shows an `icrc1_transfer` call where the caller only specifies the mandatory fields: `to` and `amount`. No `memo`, `created_at_time`, or explicit `fee` are provided. The block still contains a top-level `fee` field since the ledger applies the default transfer fee.

```
variant {
  Map = vec {
    record { "fee"; variant { Nat64 = 10_000 : nat64 } };
    record {
      "phash";
      variant {
        Blob = blob "\b8\0d\29\e5\91\60\4c\d4\60\3a\2a\7c\c5\33\14\21\27\b8\23\e9\a5\24\b7\14\43\24\4b\2d\d5\b0\86\13"
      };
    };
    record { "ts"; variant { Nat64 = 1_753_344_727_778_561_060 : nat64 } };
    record {
      "tx";
      variant {
        Map = vec {
          record { "amt"; variant { Nat64 = 85_224_322_205 : nat64 } };
          record { "from"; variant { Array = vec { variant { Blob = blob "\00\00\00\00\02\30\02\17\01\01" } } } };
          record { "op"; variant { Text = "xfer" } };
          record {
            "to";
            variant {
              Array = vec {
                variant { Blob = blob "\09\14\61\93\79\7a\6c\ab\86\17\ee\f9\5f\16\40\94\d3\f8\7c\e9\0d\9e\b2\7e\01\40\0c\79\02" };
              }
            };
          };
        }
      };
    };
  }
};
```

---

#### Example 2: Mint to user account
This example represents an `icrc1_transfer` call where the `from` account is the minting account. This results in a mint block. The caller specifies `to` and `amount`. No `fee`, `memo`, or `created_at_time` are provided.

```
variant {
  Map = vec {
    record {
      "phash";
      variant {
        Blob = blob "\c2\b1\32\6a\5e\09\0e\10\ad\be\f3\4c\ba\fd\bc\90\18\3f\38\a7\3e\73\61\cc\0a\fa\99\89\3d\6b\9e\47"
      };
    };
    record { "ts"; variant { Nat64 = 1_753_344_737_123_456_789 : nat64 } };
    record {
      "tx";
      variant {
        Map = vec {
          record { "amt"; variant { Nat64 = 500_000_000 : nat64 } };
          record {
            "to";
            variant {
              Array = vec {
                variant { Blob = blob "\15\28\84\12\af\11\b2\99\31\3a\5b\5a\7c\12\83\11\de\10\23\33\c4\ad\be\66\9f\2e\a1\a3\08" };
              }
            };
          };
          record { "op"; variant { Text = "mint" } };
        }
      };
    };
  }
};
```

---

#### Example 3: Burn from user account
This example represents an `icrc1_transfer` call where the destination `to` is the minting account. This results in a burn block. The caller specifies `from` and `amount`. No `fee`, `memo`, or `created_at_time` are provided.

```
variant {
  Map = vec {
    record {
      "phash";
      variant {
        Blob = blob "\7f\89\42\a5\be\4d\af\50\3b\6e\2a\8e\9c\c7\dd\f1\c9\e8\24\f0\98\bb\d7\af\ae\d2\90\10\67\df\1e\c1\0a"
      };
    };
    record { "ts"; variant { Nat64 = 1_753_344_740_000_000_000 : nat64 } };
    record {
      "tx";
      variant {
        Map = vec {
          record { "amt"; variant { Nat64 = 42_000_000 : nat64 } };
          record {
            "from";
            variant {
              Array = vec {
                variant { Blob = blob "\00\00\00\00\02\30\02\17\01\01" };
              }
            };
          };
          record { "op"; variant { Text = "burn" } };
        }
      };
    };
  }
};
```

##### `icrc2_transfer_from`

**Call parameters:**

```
 icrc2_transfer_from: record {
  spender_subaccount: opt blob;
  from: Account;
  to: Account;
  amount: Nat;
  fee: opt Nat;
  memo: opt Blob;
  created_at_time: opt Nat;
}
```

**Regular Transfer** — when the `to` account is not the minting account:

- `op = "xfer"`
- `from = from` (as passed in the call)
- `spender = [caller]` if `spender_subaccount` is not provided
- `spender = [caller, spender_subaccount]` if provided
- `to = to`
- `amt = amount`
- `fee = fee` if provided
- `memo = memo` if provided
- `ts = created_at_time` if provided

**Burn Transfer** — when the `to` account is the minting account:

- `op = "burn"`
- `from = from` (as passed in the call)
- `spender = [caller]` if `spender_subaccount` is not provided
- `spender = [caller, spender_subaccount]` if provided- `amt = amount`
- `fee = fee` if provided
- `memo = memo` if provided
- `ts = created_at_time` if provided



#### Example 4: Transfer from approval
This example shows an `icrc2_transfer_from` call where the recipient is a regular user account. Only the required fields are provided: `from`, `to`, and `amount`, and the spender subaccount is omitted (defaults to `null`, i.e., the default subaccount).

```
variant {
  Map = vec {
    record { "fee"; variant { Nat64 = 10_000 : nat64 } };
    record {
      "phash";
      variant {
        Blob = blob "\a0\5f\d2\f3\4c\26\73\58\00\7f\ea\02\18\43\47\70\85\50\2e\d2\1f\23\e0\dc\e6\af\3c\cf\9e\6f\4a\d8"
      };
    };
    record { "ts"; variant { Nat64 = 1_753_344_728_820_625_931 : nat64 } };
    record {
      "tx";
      variant {
        Map = vec {
          record { "amt"; variant { Nat64 = 50_419_165_435 : nat64 } };
          record {
            "from";
            variant {
              Array = vec {
                variant { Blob = blob "\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc\cc" }
              }
            };
          };
          record {
            "spender";
            variant {
              Array = vec {
                variant { Blob = blob "\00\00\00\00\02\30\02\17\01\01" }
              }
            };
          };
          record { "op"; variant { Text = "xfer" } };
          record {
            "to";
            variant {
              Array = vec {
                variant { Blob = blob "\3a\b2\17\29\53\18\70\89\73\bf\db\61\ed\28\c7\22\dc\63\2e\60\3d\50\cd\6c\9e\36\b2\ef\02" }
              }
            };
          };
        }
      };
    };
  }
};
```

---

#### Example 5: Burn from approval (to minting account with memo)
This example shows an `icrc2_transfer_from` call where the destination `to` is the minting account, resulting in a burn block. The call includes a `memo`, and no `spender_subaccount` is provided. Therefore, the `spender` field consists only of the caller's principal (default subaccount). This example demonstrates a minimal burn operation initiated via approval, with memo included.

```
variant {
  Map = vec {
    record {
      "phash";
      variant {
        Blob = blob "\9a\cd\20\3f\b0\11\fb\7f\e2\2a\1d\f2\c1\dd\22\6a\2f\1e\f6\88\d3\b0\9f\be\8d\2e\c5\70\f2\b4\a1\77"
      };
    };
    record { "ts"; variant { Nat64 = 1_753_344_750_000_000_000 : nat64 } };
    record {
      "tx";
      variant {
        Map = vec {
          record { "amt"; variant { Nat64 = 200_000 : nat64 } };
          record {
            "from";
            variant {
              Array = vec {
                variant { Blob = blob "\ab\cd\01\23\45\67\89\ab\cd\ef\01\23\45\67\89\ab\cd\ef\01\23\45\67\89\ab\cd\ef\01\23\45\67\89\ab" }
              }
            };
          };
          record {
            "spender";
            variant {
              Array = vec {
                variant { Blob = blob "\00\00\00\00\02\30\02\17\01\01" }
              }
            };
          };
          record { "op"; variant { Text = "burn" } };
          record { "memo"; variant { Blob = blob "burn by spender" } };
        }
      };
    };
  }
};
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

type GetArchivesResult = vec record {
    // The id of the archive
    canister_id : principal;

    // The first block in the archive
    start : nat;

    // The last block in the archive
    end : nat;
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

### `icrc3_supported_block_types`

```
service : {
    icrc3_supported_block_types : () -> (vec record { block_type : text; url : text }) query;
};
```
