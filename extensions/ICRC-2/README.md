# `ICRC-2`: Approve and Transfer From

## Abstract

`ICRC-2` is an extension of the base `ICRC-1` standard.
`ICRC-2` specifies a way for an account owner to delegate token transfers to a third party on the owner's behalf.

The approve and transfer-from flow is a 2-step process.
1. Account owner Alice entitles principal Bob to transfer up to X tokens from her account A by calling the `icrc2_approve` method on the ledger.
2. Bob can transfer up to X tokens from account A to any account by calling the `icrc2_transfer_from` method on the ledger.
   The number of transfers Bob can initiate from account A is not limited as long as the total amount spent is below X.

## Motivation

The approve-transfer-from pattern became popular in the Ethereum ecosystem thanks to the [ERC-20](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/) token standard.
This interface enables new application capabilities:

  1. Recurring payments.
     Alice can approve a large amount to Bob in advance, allowing Bob to make periodic transfers in small installments.
     Real-world examples include subscription services and rents.

  2. Uncertain transfer amounts.
     In some applications, such as automatic trading services, the exact price of goods is unknown in advance.
     With approve-transfer-from flow, Alice can allow Bob to trade securities on Alice's behalf, buying/selling at yet-unknown price up to a specified limit.

## Specification

> The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Canisters implementing the `ICRC-2` standard MUST implement all the functions in the `ICRC-1` interface**

**Canisters implementing the `ICRC-2` standard MUST include `ICRC-2` in the list returned by the `icrc1_supported_standards` method**

## Methods

```candid "Type definitions" +=
type Account = record {
    owner : principal;
    subaccount : opt blob;
};
```

### icrc2_approve

Entitles `spender` to transfer at most the provided token `amount` on behalf of the caller from account `{ owner = caller; subaccount = from_subaccount }`.
The number of transfers the `spender` can initiate from the caller's account is unlimited as long as the total amounts and fees of these transfers do not exceed the allowance.
The caller does not need to have the full token `amount` on the specified account for the approval to succeed, just enough tokens to pay the approval fee.
The new `spender`'s allowance for the account overrides the previous allowance value. 

```candid "Methods" +=
icrc2_approve : (ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
```

```candid "Type definitions" +=
type ApproveArgs = record {
    from_subaccount : opt blob;
    spender : principal;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type ApproveError = variant {
    BadFee : record { expected_fee : nat };
    // The caller does not have enough funds to pay the approval fee.
    InsufficientFunds : record { balance : nat };
    TooOld;
    CreatedInFuture: record { ledger_time : nat64 };
    Duplicate : record { duplicate_of : nat };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};
```

#### Preconditions

* The caller has enough fees on the `{ owner = caller; subaccount = from_subaccount }` account to pay the approval fee.

#### Postconditions

* `spender`'s allowance for the `{ owner = caller; subaccount = from_subaccount }` account is `amount`.

### icrc2_transfer_from

Transfers a token amount from between two accounts.
The ledger draws the fees from the `from` account.

```candid "Methods" +=
icrc2_transfer_from : (TransferFromArgs) -> (variant { Ok : nat; Err : TransferFromError });
```

```candid "Type definitions" +=
type TransferFromError = variant {
    BadFee : record { expected_fee : nat };
    BadBurn : record { min_burn_amount : nat };
    // The [from] account does not hold enough funds for the transfer.
    InsufficientFunds : record { balance : nat };
    // The caller exceeded its allowance.
    InsufficientAllowance : record { allowance : nat };
    TooOld;
    CreatedInFuture: record { ledger_time : nat64 };
    Duplicate : record { duplicate_of : nat };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};

type TransferFromArgs = record {
    from : Account;
    to : Account;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};
```

#### Preconditions
 
 * The caller's allowance for the `from` account is large enough to include the transfer amount and the fees.
   Otherwise, the ledger MUST return an `InsufficientAllowance` error.

* The `from` account holds enough funds to cover the transfer amount and the fees.
  Otherwise, the ledger MUST return an `InsufficientFunds` error.
 #### Postconditions

 * Caller's allowance for the `from` account decreases by the transfer amount and the fees.
 * The ledger debited the specified `amount` of tokens and fees from the `from` account.
 * The ledger credited the specified `amount` to the `to` account.

### icrc2_allowance

Returns the token allowance that the `spender` can transfer from the specified `account`.
If there is no corresponding active approval, the ledger MUST return `0`.

```candid "Methods" +=
icrc2_allowance : (AllowanceArgs) -> (nat) query;
```
```candid "Type definitions" +=
type AllowanceArgs = record {
    account : Account;
    spender : principal;
};
```
### icrc1_supported_standards

Returns the list of standards this ledger supports.
Any ledger supporting `ICRC-2` MUST include a record with the `name` field equal to `"ICRC-2"` in that list.

```candid "Methods" +=
icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
```

## Examples

### Alice deposits tokens to a canister

1. Alice wants to deposit 100 tokens on an `ICRC-2` ledger to a canister.
2. Alice calls `icrc2_approve` with `spender` set to the canister's principal and `amount` set to the token amount she wants to deposit (100) plus the transfer fee.
3. Alice can then call some `deposit` method on the canister, which calls `icrc2_transfer_from` with `from` set to Alice's (the caller) account, `to` set to the canister's account, and `amount` set to the token amount she wants to deposit (100).
4. The canister can now determine from the result of the call whether the transfer was successful.
   If it was successful, the canister can now safely commit the deposit to state and know that the tokens are in its account.

### A canister transfers tokens from Alice's account to Bob's account, on Alice's behalf

1. A canister wants to transfer 100 tokens on an `ICRC-2` ledger from Alice's account to Bob's account.
2. Alice previously approved the canister to transfer tokens on her behalf by calling `icrc2_approve` with `spender` set to the canister's principal and `amount` set to the token amount she wants to allow (100) plus the transfer fee.
3. During some update call, the canister can now call `icrc2_transfer_from` with `from` set to Alice's account, `to` set to Bob's account, and `amount` set to the token amount she wants to transfer (100).
4. Depending on the result of the call, Bob now has 100 tokens in his account, and Alice has 100 tokens less in her account.

### Alice wants to remove her allowance for a canister

1. Alice wants to remove her allowance of 100 tokens on an `ICRC-2` ledger for a canister.
2. Alice calls `icrc2_approve` on the ledger with `spender` set to the canister's principal and `amount` set to 0.
3. The canister can no longer transfer tokens on Alice's behalf.

<!--
```candid ICRC-2.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->
