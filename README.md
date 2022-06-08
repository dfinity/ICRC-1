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
decimals: () -> (nat8) query;
```

### totalSupply

Returns the total token supply.

```
totalSupply: () -> (nat) query;
```

### balanceOf

Returns the balance of the account given as argument.

```
balanceOf: (text) -> (nat) query;
```

### transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the account `principal/account_id`.

```
type TransferArgs = record {
    from_subaccount: opt SubAccount;
    to: text;
    amount: nat;
};

transfer: (TransferArgs) -> (variant { Ok: nat; Err: TransferError; });
```

The result is either the block index of the transfer or an error. The list of errors is:

```
type TransferError = variant {
    // TODO
    GenericError: text,
};
```
