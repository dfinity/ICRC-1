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
balanceOf: (record { Principal; SubAccount; }) -> (nat64) query;
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

### notify 

Notifies a downstream canister of a transaction, by calling the "transaction_notification" method of a downstream canister, with the arguments for the transaction receipt, including details of the valuetransfered the timestamp etc. Notify is a one-shot call and so does not include a return type. 
One shot calls ensure that the ledger can be upgraded even though an inter-canister call is made. 

```
notify: ( record {
    transaction_id: Nat,
    to: Principal,
}
) -> () {
```


### consume_notification
This is called by a downstream canister that has been notified. If the canister wants to ensure that it takes a signular action (not repeated/ no double spends),the canister can first consume the notification. A notification of a transaction can only ever be consumed once. 

By consuming the notification, the downstream canister does not need to worry about storing any stateto ensure notifications are only responded to once. 

```
consume_notification: (record {
    transaction_id: Nat,
}) -> (variant { Ok: Nat; Err: NotifyError; })
```


### approve_and_notify
This is an improvement on the standard approve flow. Not only do we approve a canister principal, we also call the transaction_notification method of the downstream canister with the transaction information. This means the canister itself can respond to the notification by calling transfer_from without user intervention. In addition, approve_and_notify can be invoked multiple times until a success,after which the transfer_from method should be invoked. Doing this enables us to use approve and transfer_from in a way which respects the reverse gas model of Dfinity. A down-stream canister will not allow a user to call transfer_from, as this method cannot be guarded against with inspect_message (approval information is not contained within the downstream canister, but the ledger); instead the down-stream canister will wait for a notification from a ledger canister before invoking transfer_from. 
```
approve_and_notify: (record {
    spender: Principal,
    value: Nat,
}) -> (variant { Ok: nat64; Err: TransferError; })
```
