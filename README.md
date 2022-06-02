# ICRC-1 Token Standard

The ICRC-1 is a standard for Fungible Tokens on the [Internet Computer](https://internetcomputer.org).

## Data structures

```

type TransactionResponse = {
  #ok : { //index confirmed
   #index: nat64;
   #hash : Blob; //to allow for hash blobs
  }; 
  #err: TransactionError;
  #pending: Blob; //hash if pending
  #noop; //to support "free" operations

```

## Methods

### name

Returns the name of the token, e.g. `MyToken`.

```
name_ic1: () -> (text) query;
```

### symbol

Returns the symbol of the token, e.g. `ICP`.

```
symbol_ic1: () -> (text) query;
```

### decimals

Returns the number of decimals the token uses, e.g. `8`, means to divide the token amount by `100000000` to get its user representation.

```
decimals_ic1: () -> (nat32) query;
```

### totalSupply

Returns the total token supply.

```
totalSupply_ic1: () -> (nat64) query;
```

### balanceOf

Returns the balance of the account given as argument.

```
balanceOf_ic1: (record { Principal; SubAccount; }) -> (nat64) query;
```

### transfer

Transfers `amount` of tokens from the account `(caller, from_subaccount)` to the account `(to_principal, to_subaccount)`.

```
type TransferArgs = record {
    from_subaccount: opt SubAccount;
    to_principal: Principal;
    to_subaccount: opt SubAccount;
    amount: nat64;
    callback: opt Principal;  //what if someone puts a user principal here?  Does the IC know not to call it?
    memo: nat32;
    fee: nat64;
    timestamp: int;
};


transfer_icrc: (TransferArgs) -> TransactionResponse;
```

The result is either the block index or hash of the transfer, a pending hash, a noop, or an error. The list of errors is:

```
type TransferError = variant {
    // TODO
    GenericError: text,
};
```

The canister refrenced in the callback should implement the following signature:

```
    transfer_notified_ic1 : (BlockArgs) -> () //one shot call
```

### Re-notify

Asks a ledger to re-notify of a transactions. Returns the index for any fee charged. Fee is optional at the discression of the ledger.

Renotify will call the ame transfer_notified_ic1 endpoint as a regular transfer.

Note: With archive nodes this cold get tricky and slow.

```
type NotifyArgs = record {
    index: nat64;               // Block Desirred
    subaccount: opt SubAccount. // Sub account to charge the fee from
    fee: nat64;                 // fee willing to pay
};

renotify_ic1: (NotifyArgs) -> TransactionResponse;
```


### Approval Flow

Allows a user to approve a canister to transfer funds from their account.

#### approve

Approves the to spend account to pull tokens. They should be moved from the to/default sub account to a specific sub account indicated by 32 Byte hash of 'ic1-approve//' + ToPrincipal (perhaps not very private?) to prevent double spend/reentrance attacks.

```
type ApproveArgs = record {
    to: principal;                   // User approved to spend
    to_subaccount: opt SubAccount    // Sub account to send the tokens to; If sub account is null the to address canmove to any sub account
    from_subaccount: opt SubAccount. // sub account to pull tokens from; If sub account is null use the default account
    amount: nat64;
    fee: nat64;                      // fee willing to pay for the approve
};

approve_ic1: (ApproveArgs) -> TransactionResponse;
```


#### transferFrom

Moves the tokens

```
type TransferFromArgs = record {
    to: principal;                   // User approved to spend
    to_subaccount: opt SubAccount;    // Sub account to send the tokens to; If sub account is null the to address canmove to any sub account
    from: principal;
    from_subaccount: opt SubAccount; // sub account to pull tokens from; If sub account is null use the default account
    amount: nat64;
    fee: nat64;                      // fee willing to pay for the approve
};

transferFrom_ic1: (TransferFromArgs) -> TransactionResponse;
```
