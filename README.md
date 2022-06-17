# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data

### account

A `principal` can have multiple accounts. Each account of a `principal` is identified by a 32-byte string called `subaccount`. Therefore an account corresponds to a pair `(principal, subaccount)`.

The account identified by the subaccount with all bytes set to 0 is the _default account_ of the `principal`.

## Methods

### metadata

Returns the list of metadata entries for this ledger.
See the "Metadata" section below.

```
metadata: () -> (vec { record { text; text } }) query;
```

### metadataKeys

Returns all the metadata keys.
Equivalient to fetching the metadata and extracting the keys.

```
metadataKeys: () -> (vec text) query;
```

### metadataByKey

Returns a single value from the `metadata` map.
Equivalent to fetching the metadata entries and looking up the value by the key.

```
metadataByKey: (text) -> (opt text) query;
```

### totalSupply

Returns the total token supply.

```
totalSupply: () -> (nat32) query;
```

### balanceOf

Returns the balance of the account given as argument.

```
balanceOf: (record { of: principal; subaccount: opt SubAccount; }) -> (nat64) query;
```

### transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the account `(to_principal, to_subaccount)`.

```
type TransferArgs = record {
    from_subaccount: opt SubAccount;
    to_principal: Principal;
    to_subaccount: opt SubAccount;
    amount: nat64;
};

transfer: (TransferArgs) -> (variant { Ok: nat64; Err: TransferError; });
```

The result is either the block index of the transfer or an error. The list of errors is:

```
type TransferError = variant {
    // TODO
    GenericError: text,
};
```

## Metadata

A ledger can expose metadata to simplify integration with wallets and improve user experience.
The client can use `metadata` and `metadataByKey` methods to fetch the metadata. 
All the metadata entries are optional.

### Key format

The metadata keys can be arbitrary unicode strings and must follow the pattern `<namespace>:<key>`, where `<namespace>` is a string that does not contain colons.
Namespace `icrc1` is reserved for keys defined in this standard.

### Standard metadata entries

| Key | Example value | Semantics |
| --- | ------------- | --------- |
| `icrc1:symbol` | `XTKN` | The token currency code (see [ISO-4217](https://en.wikipedia.org/wiki/ISO_4217)). |
| `icrc1:name` | `Test Token` | The name of the token. |
| `icrc1:decimals` | `8` | The number of decimals the token uses. For example, 8 means to divide the token amount by 10<sup>8</sup> to get its user representation. |

