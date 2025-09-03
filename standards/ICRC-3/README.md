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

Servers MUST serve the block log as a list of `Value` where each `Value` represents a single block in the block log.

## Value Hash

`ICRC-3` specifies a standard hash function over `Value`.

This hash function SHOULD be used by Ledgers to calculate the hash of the parent of a block and by clients to verify the downloaded block log.

The hash function is the [representation-independent hashing of structured data](https://internetcomputer.org/docs/current/references/ic-interface-spec#hash-of-map) used by the IC:
- the hash of a `Blob` is the hash of the bytes themselves
- the hash of a `Text` is the hash of the bytes representing the text
- the hash of a `Nat` is the hash of the [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128) encoding of the number
- the hash of an `Int` is the hash of the [`sleb128`](https://en.wikipedia.org/wiki/LEB128#Signed_LEB128) encoding of the number
- the hash of an `Array` is the hash of the concatenation of the hashes of all the elements of the array
- the hash of a `Map` is the hash of the concatenation of all the hashed items of the map sorted lexicographically. A hashed item is the tuple composed by the hash of the key and the hash of the value.

Pseudocode for representation-independent hashing of `Value`, together with test vectors to check compliance with the specification can be found [`here`](HASHINGVALUES.md). 

## Blocks Verification

The Ledger MUST certify the last block (tip) recorded. The Ledger MUST allow to download the certificate via the `icrc3_get_tip_certificate` endpoint. The certificate follows the [IC Specification for Certificates](https://internetcomputer.org/docs/current/references/ic-interface-spec#certification). The certificate is comprised of a tree containing the certified data and the signature. The tree MUST contain two labeled values (leaves):
1. `last_block_index`: the index of the last block in the chain. The values MUST be expressed as [`leb128`](https://en.wikipedia.org/wiki/LEB128#Unsigned_LEB128)
2. `last_block_hash`: the hash of the last block in the chain

Clients SHOULD download the tip certificate first and then download the blocks backward starting from `last_block_index` and validate the blocks in the process.

Validation of block `i` is done by checking the block hash against
1. if `i + 1 < len(chain)` then the parent hash `phash` of the block `i+1`
2. otherwise the `last_block_hash` in the tip certificate.

## Generic Block Schema

An ICRC-3 compliant Block

1. MUST be a `Value` of variant `Map`
2. MUST contain a field `phash: Blob` which is the hash of its parent if it has a parent block
3. SHOULD contain a field `btype: Text` which uniquely describes the type of the Block. If this field is not set then the block type falls back to ICRC-1 and ICRC-2 for backward compatibility purposes


### Kinds of Blocks

An ICRC-3 block can record different kinds of information. Some blocks record the result of a transaction submitted by a user. These typically contain a `tx` field describing the user’s intent and any parameters they provided.

Other blocks may be created by the ledger itself, for example during an upgrade, migration, or system operation, to record changes in ledger state that did not come from a user call.

The `tx` field, when present, encodes the **intent** or **state change payload** associated with the block:
- In user-initiated blocks, `tx` reflects the call parameters, subject to the canonical mapping defined for that block type.
- In system-generated blocks, `tx` may capture the minimal structure required to interpret the block’s meaning and effect, as defined in the specification for that block type.

The exact meaning of a block and its `tx` structure is determined by its block type.  
Block types and their schemas are defined either by legacy standards (e.g., ICRC-1, ICRC-2) or by newer standards introducing `btype`-tagged blocks.



## Principles and Rules for ICRC-3 Blocks

The following principles guide the evolution and interpretation of ICRC-3 and any standards that build on it.

### 1. Core State Transitions
- Every block type MUST define the **core state transition** it represents: the deterministic change to ledger state implied by the block’s minimal `tx` structure, *ignoring fees or ledger-specific policies*.  
- This transition is the canonical meaning of a block — what balances, allowances, or other state variables change as a direct consequence of the block.  
- Fee handling, metadata, and ledger-specific policies are layered on top of this transition.

### 2. Separation of `btype` and `tx`
- The `btype` field defines the **minimal semantic structure** of a block — the set of fields in `tx` required to fully determine its core state transition.  
- Standards that introduce a new `btype` MUST:
  - Assign a unique identifier for the `btype`.
  - Specify the minimal `tx` structure required for interpreting that block type.
  - Define the block’s **core state transition** in terms of this minimal structure.
- Standards that define methods producing blocks MUST:
  - Specify which `btype` the method produces.
  - Define the **canonical mapping** from method call parameters to the `tx` field of the resulting block.
  - Ensure that `tx` contains only parameters explicitly provided by the caller (except where the block type definition requires otherwise).

### 3. Avoiding Collisions in `tx`
- To avoid collisions between transactions originating from different standards, the canonical `tx` mapping MUST include:
  - An operation field (`op`) whose value is namespaced using the standard’s number as a prefix, e.g., `122freeze_account`.
- No two standardized methods may produce `tx` values that are indistinguishable when interpreted under ICRC-3 rules.

### 4. Inclusion of the User Call in `tx`
- The `tx` field must faithfully capture the structure of the user call that triggered the block.
- All call parameters that are part of the method’s canonical mapping MUST be included exactly as provided by the caller.
- Optional parameters that were not present in the call MUST be omitted from `tx`.

### 5. Future-Proofing and Extensibility
- Additional non-semantic fields (e.g., metadata, hashes, references) MAY be added to `tx` without introducing a new `btype`, provided:
  - They do not affect the block’s **core state transition**.
  - They are ignored by block verification and interpretation logic that only relies on the minimal `tx` structure defined by the `btype`.
- Any change to the minimal semantic structure of a block REQUIRES introducing a new `btype`.

### Note on Ledger-Specific Fields
- Blocks may include additional fields specific to a given standard or ledger (e.g., `fee`, metadata, references).  
- ICRC-3 defines how such fields are recorded and verified, but **does not define their economic or behavioral semantics**. Those semantics must be specified by the standard that introduces the block type (e.g., fee rules in ICRC-107).

## Semantics of Blocks: Evaluation Model

To ensure consistency across standards and implementations, the semantics of any block must be interpretable through the following evaluation model. Each standard that defines a block type specifies how to “plug into” this model (by defining its minimal `tx` schema, pre-fee transition, fee payer, etc.).

1. Identify block type  
   • If `btype` is present, use it.  
   • If no `btype`, fall back to legacy ICRC-1/2 inference from `tx.op`.

2. Validate `tx` structure  
   • Check that `tx` includes all required fields defined for the block type.  
   • Ensure no extra *semantic* fields beyond those defined by the block type are present.  
   • Optional caller-provided fields may appear if allowed by the canonical mapping.

3. Derive pre-fee state transition  
   • Apply the deterministic state change implied by `tx`, ignoring any fees.  
   • Example: debit/credit balances, mint, burn, update allowance.

4. Apply fee (if applicable)  
   • If the block type involves fees, determine the **effective fee** following ICRC-107.  
   • Deduct the fee from the account designated as the **fee payer** for this block type.  
   • Adjust balances accordingly (e.g., for mints: `to` receives `amt – fee`).

5. Enforce validity conditions  
   • Ensure balances remain non-negative.  
   • Verify sufficient funds to cover `amt + fee` (where applicable).  
   • Require `fee ≤ amt` for mint blocks.  
   • Enforce any invariants specified by the block type’s standard.


## Interaction with Other Standards

ICRC-3 defines how blocks are structured and verified. Other standards extend this by either:  
(1) introducing new block types (`btype`), or  
(2) defining canonical mappings from standardized method calls to existing block types.

### Standards That Introduce Block Types
A standard that defines a new block type MUST:
- Assign a unique `btype`.  
- Specify the minimal `tx` structure required to interpret the block and determine its effect on ledger state.  
- Define semantics using the **Semantics of Blocks: Evaluation Model** (pre-fee transition, fee hook, post-conditions).  
- If the block type involves fees, reference the applicable fee standard (e.g., ICRC-107) and **define who pays**, via a fee payer expression resolvable from block fields.

### Standards That Define Methods
A standard that defines a method which produces blocks MUST:
- Specify which `btype` (if any) the method produces.  
- Define the canonical mapping from method inputs to the `tx` field of the resulting block.  
- Ensure all required fields from the block type’s minimal schema are populated.  
- Include only caller-provided optional fields; omit optionals that were not supplied.  
- Include an `op` field in `tx` to identify the operation and avoid collisions.

This division of responsibility ensures that:
- Block types define **what blocks mean** (semantics).
- Methods define **how blocks are created** (intent capture).
- Tooling and clients can rely on predictable, non-colliding `tx` values.


#### Namespacing for Operations
To avoid collisions across standards, `tx.op` MUST be namespaced:
- `op = icrc_number op_name`  
- `icrc_number`: a non-zero digit followed by zero or more digits  
- `op_name`: starts with a lowercase letter, then lowercase letters, digits, `_` or `-`  
**Examples:** `1transfer`, `2transfer_from`, `123freeze_account`.





### Note on Fees
ICRC-3 itself does not define fee semantics.  
Standards that define block types which involve fees MUST follow **ICRC-107 (Fee Handling in Blocks)**.
ICRC-3 only requires that the fee payer for a block type be clearly defined, so that fee responsibility is unambiguous.


## Supported Standards

An ICRC-3 compatible Ledger MUST expose an endpoint listing all the supported block types via the endpoint `icrc3_supported_block_types`.

- For **typed** blocks, the ledger MUST only produce blocks whose `"btype"` value is included in this list.
- For **legacy** ICRC-1/2 blocks (no `"btype"`), the ledger MUST include the conventional identifiers (e.g., `"1xfer"`, `"2approve"`) in this list to advertise support, even though the blocks themselves do not carry a `"btype"` field.


## [ICRC-1](../ICRC-1/README.md) and [ICRC-2](../ICRC-2/README.md) Block Schema


This section describes how ICRC-1 and ICRC-2 operations are represented in ICRC-3-compliant blocks.  These blocks follow the **legacy format**, meaning they do not have a `btype` field.  
Instead, their type is inferred directly from the content of the `tx` field, which records the canonical mapping of the original method call.

### Legacy ICRC-1 and ICRC-2 Block Structure

ICRC-1 and ICRC-2 blocks **MUST NOT** include a `btype` field. These standards use the legacy block format where the block type is determined exclusively from the content of the `tx` field.  

Legacy blocks therefore follow a fixed generic structure, with semantics inferred from `tx.op`.

---

#### Generic Legacy Block

A legacy block:

- **MUST** be a `Value::Map` containing at least:
  - `"phash"`: `Blob` — the parent hash.
  - `"ts"`: `Nat` — the timestamp set by the ledger when the block was created.
  - `"tx"`: `Value::Map` — representing the user’s transaction intent.
- **MAY** include:
  - `"fee": Nat` — the fee actually charged by the ledger, if any.

---

#### Transfer Block (`op = "xfer"`)

**Structure**
- **MUST** contain `tx.op = "xfer"`.
- **MUST** contain `tx.from : Account`.
- **MUST** contain `tx.to : Account`.
- **MUST** contain `tx.amt : Nat`.
- **MAY** contain `tx.fee : Nat` if provided by the caller.
- **MAY** contain `tx.memo : Blob` if provided by the caller.
- **MAY** contain `tx.ts : Nat` if provided by the caller (`created_at_time`).
- **MAY** contain `tx.spender : Account` if created via `icrc2_transfer_from`.

**Semantics**  
Transfers debit `amt` (and any fee) from `from` and credit `amt` to `to`.  
If `tx.spender` is present, the operation is executed under an approval, which must cover at least `amt + fee`. The allowance is reduced accordingly.  

**Fee payer:** `from`.

---

#### Mint Block (`op = "mint"`)

**Structure**
- **MUST** contain `tx.op = "mint"`.
- **MUST** contain `tx.to : Account`.
- **MUST** contain `tx.amt : Nat`.
- **MUST NOT** contain `tx.from`.
- **MAY** contain `tx.spender : Account`.
- **MAY** contain `tx.memo : Blob` if provided by the caller.
- **MAY** contain `tx.ts : Nat` if provided by the caller.

**Semantics**  
Mints create `amt` new tokens. If a fee is charged, it is deducted from `to` immediately, so `to` receives `amt - fee` (require `fee ≤ amt`).  
If `tx.spender` is present, the mint is executed under an approval on the minting account; that approval **MUST** be at least `amt + fee` and **MUST** be reduced by `amt + fee`.



**Fee payer:** `to`.

---

#### Burn Block (`op = "burn"`)

**Structure**
- **MUST** contain `tx.op = "burn"`.
- **MUST** contain `tx.from : Account`.
- **MUST** contain `tx.amt : Nat`.
- **MUST NOT** contain `tx.to`.
- **MAY** contain `tx.fee : Nat` if provided by the caller.
- **MAY** contain `tx.memo : Blob` if provided by the caller.
- **MAY** contain `tx.ts : Nat` if provided by the caller.

**Semantics**  
Burns remove `amt` tokens from `from`. Any fee is also debited from `from`.  

**Fee payer:** `from`.

---

#### Approve Block (`op = "approve"`)

**Structure**
- **MUST** contain `tx.op = "approve"`.
- **MUST** contain `tx.from : Account`.
- **MUST** contain `tx.spender : Account`.
- **MUST** contain the allowance field as defined by ICRC-2 (e.g., `tx.amt : Nat`).
- **MAY** contain `tx.fee : Nat` if provided by the caller.
- **MAY** contain `tx.memo : Blob` if provided by the caller.
- **MAY** contain `tx.ts : Nat` if provided by the caller.

**Semantics**  
Approvals set or update the allowance of `spender` on `from`.  
Any subsequent `xfer` block with `tx.spender` consumes the allowance.  
Fees (if any) are debited from `from`.  
If the approval is set on the minting account, it can be consumed by `icrc2_transfer_from` mints; such mints reduce the allowance by `amt + fee`.


**Fee payer:** `from`.

---

#### Notes on Fee Representation (Legacy Blocks)

- The **effective fee** for a block is computed as:
  1. If a top-level `"fee"` is present, that is the fee charged by the ledger.
  2. Otherwise, if `tx.fee` is present, the effective fee equals `tx.fee`.
  3. Otherwise, the fee is `0`.

- `tx.fee` records what the caller supplied; when the top-level `"fee"` is absent, it also implies the ledger charged that same amount.
- If both top-level `"fee"` and `tx.fee` are present and differ, the top-level `"fee"` is authoritative.
- Ledgers **MAY** omit the top-level `"fee"` when it equals `tx.fee` to save space.
- The **destination/handling** of the fee (e.g., collecting account, burn) is specified by the fee standard (see **ICRC-107, Fee Handling in Blocks**); ICRC-3 only standardizes how fees are recorded in blocks, not where they go.



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
- `from` and `fee` MUST NOT be present

**Transfer to the Minting Account (→ Burn)** — when `to` equals the minting account:

- `op = "burn"`
- `from = [caller]` if `from_subaccount` is not provided  
- `from = [caller, from_subaccount]` if provided
- `amt = amount`
- `memo = memo` if provided
- `ts = created_at_time` if provided  
- `to` and `fee` MUST NOT be present


### Fee Payer and Balance Effects (Legacy ICRC-1/2)

The rules below define **who pays** and how the **effective fee** (if any) affects balances for legacy blocks (no `btype`; kind inferred from `tx`). The authoritative charged amount is the top-level `fee : Nat` when present; `tx.fee` (if present) reflects the caller input only.

#### `icrc1_transfer`
- `op = "xfer"` → **Payer:** `from`  
  • Debited from `from`: `amt + fee` (if a fee is charged)  
  • Credited to `to`: `amt`
- `op = "burn"` → **Payer:** `from`  
  • Debited from `from`: `amt + fee` (if a fee is charged)  
  • Burned: `amt`
- `op = "mint"` → **Payer:** `to`  
  • Credited to `to`: `amt - fee` (if a fee is charged; require `fee ≤ amt`)  
  • Minted gross amount: `amt` (with `fee` immediately taken from `to`)

#### `icrc2_transfer_from`
- `op = "xfer"` → **Payer:** `from` (authorized by `spender`)  
  • Debited from `from`: `amt + fee` (if a fee is charged)  
  • Credited to `to`: `amt`
- `op = "burn"` → **Payer:** `from` (authorized by `spender`)  
  • Debited from `from`: `amt + fee` (if a fee is charged)  
  • Burned: `amt`
- `op = "mint"` → Payer: to (authorized by spender under an approval on the minting account)
• Credited to `to: amt - fee` (if a fee is charged; require `fee ≤ amt`)
• Allowance on the minting account (for spender) is reduced by `amt + fee`

#### `icrc2_approve`
- **Payer:** `from` (the account whose allowance is modified)  
  • Debited from `from`: `fee` (if a fee is charged)

**Notes**  
- A fee may be charged even if `tx.fee` is absent; the charged fee is indicated by a top-level `fee`.  
- If no top-level `fee` is present, the effective fee is `0`.  
- Implementations must reject calls that cannot satisfy the fee rule (e.g., `fee > amt` for mint; or insufficient balance for `amt + fee` debits).



### Canonical Examples of `icrc1_transfer` Blocks

Each of the following examples represents a canonical block resulting from an `icrc1_transfer` call. These examples illustrate different scenarios depending on which optional fields were included in the call. Only parameters explicitly provided by the caller appear in the resulting `tx`.



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
- `spender = [caller, spender_subaccount]` if provided
- `amt = amount`
- `fee = fee` if provided
- `memo = memo` if provided
- `ts = created_at_time` if provided


**Mint Transfer** — when the `from` account is the minting account:

- `op = "mint"`
- `spender = [caller]` if `spender_subaccount` is not provided
- `spender = [caller, spender_subaccount]` if provided
- `to = to`
- `amt = amount`
- `memo = memo` if provided
- `ts = created_at_time` if provided
- `from` and `fee` **MUST NOT** be present


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
