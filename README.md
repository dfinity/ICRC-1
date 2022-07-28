# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data

### account

A `principal` can have multiple accounts. Each account of a `principal` is identified by a 32-byte string called `subaccount`. Therefore an account corresponds to a pair `(principal, subaccount)`.

The account identified by the subaccount with all bytes set to 0 is the _default account_ of the `principal`.

```candid "Type definitions" +=
type Subaccount = blob;
type Account = record { "principal": principal; subaccount: opt Subaccount; };
```

## Methods

### icrc1_name

Returns the name of the token (e.g., `MyToken`).

```candid "Methods" +=
icrc1_name : () -> (text) query;
```

### icrc1_symbol

Returns the symbol of the token (e.g., `ICP`).

```candid "Methods" +=
icrc1_symbol : () -> (text) query;
```

### icrc1_decimals

Returns the number of decimals the token uses (e.g., `8` means to divide the token amount by `100000000` to get its user representation).

```candid "Methods" +=
icrc1_decimals : () -> (nat8) query;
```

### icrc1_metadata

Returns the list of metadata entries for this ledger.
See the "Metadata" section below.

```candid "Type definitions" +=
type Value = variant { Nat : nat; Int : int; Text : text; Blob : blob };
```

```candid "Methods" +=
icrc1_metadata : () -> (vec record { text; Value }) query;
```

### icrc1_total_supply

Returns the total token supply.

```candid "Methods" +=
icrc1_total_supply : () -> (nat) query;
```

### icrc1_balance_of

Returns the balance of the account given as argument.

```candid "Methods" +=
icrc1_balance_of : (Account) -> (nat) query;
```

### icrc1_transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the `Account`.

```candid "Type definitions" +=
type TransferArgs = record {
    from_subaccount: opt Subaccount;
    to: Account;
    amount: nat;
    fee: opt nat;
    memo: opt nat64;
    created_at_time: opt nat64;
};

type TransferError = variant {
    BadFee : record { expected_fee : nat };
    BadBurn : record { min_burn_amount : nat };
    InsufficientFunds : record { balance : nat };
    TooOld : record { allowed_window_nanos : nat64 };
    CreatedInFuture;
    Duplicate : record { duplicate_of : nat };
    GenericError: record { error_code : nat; message : text };
};
```

```candid "Methods" +=
icrc1_transfer : (TransferArgs) -> (variant { Ok: nat; Err: TransferError; });
```

The caller pays the `fee`.
If the caller does not set the `fee` argument, the ledger applies the default transfer fee.
If the `fee` argument does not agree with the ledger fee, the ledger MUST return `variant { BadFee = record { expected_fee = ... } }` error.

The `memo` parameter is an arbitrary integer that has no meaning to the ledger.
The ledger MAY use the `memo` argument for transaction deduplication.

The `created_at_time` parameter indicates the time (as nanoseconds since the UNIX epoch in the UTC timezone) at which the client constructed the transaction.
The ledger MAY reject transactions that have `created_at_time` argument too far in the past or the future, returning `variant { TooOld = record { allowed_window_nanos = ... } }` and `variant { CreatedInFuture }` errors correspondingly.

The result is either the transaction index of the transfer or an error.

### icrc1_supported_standards

Returns the list of standards this ledger implements.
See the ["Extensions"](#extensions) section below.

```candid "Methods" +=
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

<!--
```candid ICRC-1.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->
