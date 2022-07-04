# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data

### account

A `principal` can have multiple accounts. Each account of a `principal` is identified by a 32-byte string called `subaccount`. Therefore an account corresponds to a pair `(principal, subaccount)`.

The account identified by the subaccount with all bytes set to 0 is the _default account_ of the `principal`.

## Methods

### name

Returns the name of the token, e.g. `MyToken`.

```
name: () -> (text) query;
```

### symbol

Returns the symbol of the token, e.g. `ICP`.

```
symbol: () -> (text) query;
```

### decimals

Returns the number of decimals the token uses, e.g. `8`, means to divide the token amount by `100000000` to get its user representation.

```
decimals: () -> (nat32) query;
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

### extensions

Returns the list of extensions this ledger supports.
See the ["Extensions"](#extensions) section below.

```
extensions : () -> (vec text) query;
```

## Extensions <span id="extensions"></span>

The core standard intentionally excludes some ledger functions that are essential for building an extensive DeFi ecosystem, for example:

  - Reliable transaction notifications for smart contracts.
  - The block structure and the interface to fetch blocks.
  - Pre-signed transactions.

To accommodate these and other future extensions, the standard defines the `extensions` endpoint.
This endpoint returns will return names of other ICRC specifications (e.g., `"ICRC-42"`) supported by the ledger.
