# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data

### account

A `principal` can have multiple accounts. Each account of a `principal` is identified by a 32-byte string called `subaccount`. Therefore an account corresponds to a pair `(principal, subaccount)`.

The account identified by the subaccount with all bytes set to 0 is the _default account_ of the `principal`.

## Methods

### icrc1_name

Returns the name of the token (e.g., `MyToken`).

```
icrc1_name : () -> (text) query;
```

### icrc1_symbol

Returns the symbol of the token (e.g., `ICP`).

```
icrc1_symbol : () -> (text) query;
```

### icrc1_decimals

Returns the number of decimals the token uses (e.g., `8` means to divide the token amount by `100000000` to get its user representation).

```
icrc1_decimals : () -> (nat8) query;
```

### icrc1_metadata

Returns the list of metadata entries for this ledger.
See the "Metadata" section below.

```
type Value = variant { Nat : nat; Int : int; Text : text; Blob : blob };

icrc1_metadata : () -> (vec { record { text; Value } }) query;
```

### icrc1_total_supply

Returns the total token supply.

```
icrc1_total_supply : () -> (nat) query;
```

### icrc1_balance_of

Returns the balance of the account given as argument.

```
icrc1_balance_of : (record { of: principal; subaccount: opt SubAccount; }) -> (nat) query;
```

### icrc1_transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the account `(to_principal, to_subaccount)`. The `fee` is paid by the `caller`.

```
type TransferArgs = record {
    from_subaccount: opt SubAccount;
    to_principal: Principal;
    to_subaccount: opt SubAccount;
    amount: nat;
    fee: opt nat;
    memo: opt nat64;
    created_at_time: opt Timestamp;
};

icrc1_transfer : (TransferArgs) -> (variant { Ok: nat; Err: TransferError; });
```

The result is either the block index of the transfer or an error.

### icrc1_supported_standards

Returns the list of standards this ledger implements.
See the ["Extensions"](#extensions) section below.

```
icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
```

The result of the call should always have at least one entry,

```candid
record { name = "ICRC-1"; url = "https://github.com/dfinity/ICRC-1" }
```

## Extensions <span id="extensions"></span>

The base standard intentionally excludes some ledger functions essential for building a rich DeFi ecosystem, for example:

  - Reliable transaction notifications for smart contracts.
  - The block structure and the interface for fetching blocks.
  - Pre-signed transactions.

The standard defines the `icrc1_supported_standards` endpoint to accommodate these and other future extensions.
This endpoint returns names of all specifications (e.g., `"ICRC-42"` or `"DIP-20"`) implemented by the ledger.

## Metadata

A ledger can expose metadata to simplify integration with wallets and improve user experience.
The client can use the `icrc1_metadata` method to fetch the metadata entries. 
All the metadata entries are optional.

### Key format

The metadata keys are arbitrary unicode strings and must follow the pattern `<namespace>:<key>`, where `<namespace>` is a string not containing colons.
Namespace `icrc1` is reserved for keys defined in this standard.

### Standard metadata entries

| Key | Example value | Semantics |
| --- | ------------- | --------- |
| `icrc1:symbol` | `variant { Text = "XTKN" }` | The token currency code (see [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217)). When present, should be the same as the result of the `symbol` query call. |
| `icrc1:name` | `variant { Text = "Test Token" }` | The name of the token. When present, should be the same as the result of the `name` query call. |
| `icrc1:decimals` | `variant { Nat = 8 }` | The number of decimals the token uses. For example, 8 means to divide the token amount by 10<sup>8</sup> to get its user representation. When present, should be the same as the result of the `decimals` query call. |

