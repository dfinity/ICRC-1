# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data

### account

A `principal` can have multiple accounts. Each account of a `principal` is identified by a 32-byte string called `subaccount`. Therefore an account corresponds to a pair `(principal, subaccount)`.

The account identified by the subaccount with all bytes set to 0 is the _default account_ of the `principal`.

## Methods

### icrc1_name

Returns the name of the token, e.g. `MyToken`.

```
icrc1_name: () -> (text) query;
```

### icrc1_symbol

Returns the symbol of the token, e.g. `ICP`.

```
icrc1_symbol: () -> (text) query;
```

### icrc1_decimals

Returns the number of decimals the token uses, e.g. `8`, means to divide the token amount by `100000000` to get its user representation.

```
icrc1_decimals: () -> (nat32) query;
```

### icrc1_totalSupply

Returns the total token supply.

```
icrc1_totalSupply: () -> (nat32) query;
```

### icrc1_balanceOf

Returns the balance of the account given as argument.

```
icrc1_balanceOf: (record { of: principal; subaccount: opt SubAccount; }) -> (nat64) query;
```

### icrc1_transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the account `(to_principal, to_subaccount)`.

```
type TransferArgs = record {
    from_subaccount: opt SubAccount;
    to_principal: Principal;
    to_subaccount: opt SubAccount;
    amount: nat64;
};

icrc1_transfer: (TransferArgs) -> (variant { Ok: nat64; Err: TransferError; });
```

The result is either the block index of the transfer or an error. The list of errors is:

```
type TransferError = variant {
    // TODO
    GenericError: text,
};
```
