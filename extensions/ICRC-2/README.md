# `ICRC-2`: Approve and Transfer From

## Abstract

`ICRC-2` is an extension to the base `ICRC-1` standard. It adds the ability to approve a third party, and then that third party can transfer tokens on your behalf.

The approve and transfer-from flow is a 2-step process.
1. Signer A approves X tokens for signer b
2. Signer B can transfer on behalf of signer A, up to the allowance X, or Signer B’s total balance

## Motivation

At the time of writing, the base `ICRC-1` standard does not have first class support for canister based interactions. This is because the `transfer` method does not allow for a third-party to transfer tokens on behalf of a user. This is a common pattern in the ERC20 standard, and is useful for canister based interactions.

## Specification

> The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Canisters implementing the `ICRC-2` standard MUST implement all the functions in the `ICRC-1` interface**

**Canisters implementing the `ICRC-2` standard MUST include `ICRC-2` in the list returned by the `icrc1_supported_standards` method**

```candid
// The `ICRC-2` standard extends the `ICRC-1` standard

type ApproveArgs = record {
    spender : principal;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type TransferFromArgs = record {
    from : Account;
    to : Account;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type AllowanceArgs = record {
    owner : Account;
    spender : principal;
};

service : {
    icrc1_* : (*) -> *;
    
    icrc2_approve : (ApproveArgs) -> (variant { Ok } | variant { Err : TransferError });
    icrc2_transfer_from : (TransferFromArgs) -> (variant { Ok : nat; Err : TransferError });
    icrc2_allowance : (AllowanceArgs) -> (nat) query;
}
```

## Implementation Guidelines

### Approve (`icrc2_approve`)

- If a user sets an allowance of 0, it is equivalent to removing the allowance, and canisters SHOULD remove the allowance from their internal state

### Transfer-From (`icrc2_transfer_from`)

- The allowance is checked before the transfer is executed, and the allowance is decremented after the transfer is executed
- If the `from` account does not have enough tokens to transfer, the canister MUST return `InsufficientFunds` error
- If the `caller` does not have enough allowance for `from` to transfer, the canister MUST return `InsufficientAllowance` error

### Allowance (`icrc2_allowance`)

- The canister MUST return the total allowance for the given `owner` and `spender`
- The canister MUST return `0` if the allowance does not exist

### Supported Standards List (`icrc1_supported_standards`)

- The canister MUST include `ICRC-2` in the list returned by the `icrc1_supported_standards` method

## Examples

### Alice deposits tokens to a canister

1. Alice wants to deposit 100 tokens on an `ICRC-2` ledger to a canister id
2. Alice calls `icrc2_approve` with `spender` set to the canister's principal, and `amount` set to the amount of tokens she wants to deposit (100).
3. Alice can then call some `deposit` method on the canister, which calls `icrc2_transfer_from` with `from` set to Alice's (the caller) account, `to` set to the canister's account, and `amount` set to the amount of tokens she wants to deposit (100).
4. The canister can now determine from the result of the call if the transfer was successful or not. If it was successful, the canister can now commit the deposit to state safely and know that the tokens are in its account.

### A canister transfers tokens from Alice's account to Bob's account, on Alice's behalf

1. A canister wants to transfer 100 tokens on an `ICRC-2` ledger from Alice's account to Bob's account
2. Alice previously approved the canister to transfer tokens on her behalf by calling `icrc2_approve` with `spender` set to the canister's principal, and `amount` set to the amount of tokens she wants to allow (100).
3. During some update call, the canister can now call `icrc2_transfer_from` with `from` set to Alice's account, `to` set to Bob's account, and `amount` set to the amount of tokens she wants to transfer (100).
4. Depending on the result of the call, Bob now has 100 tokens in his account, and Alice has 100 tokens less in her account.

### Alice wants to remove her allowance for a canister

1. Alice wants to remove her allowance of 100 tokens on an `ICRC-2` ledger for a canister
2. Alice calls `icrc2_approve` on the ledger with `spender` set to the canister's principal, and `amount` set to 0.
3. The canister can now no longer transfer tokens on Alice's behalf.
