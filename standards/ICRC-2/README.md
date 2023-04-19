# `ICRC-2`: Approve and Transfer From

| Status |
|:------:|
| Draft  |

## Abstract

`ICRC-2` is an extension of the base `ICRC-1` standard.
`ICRC-2` specifies a way for an account owner to delegate token transfers to a third party on the owner's behalf.

The approve and transfer-from flow is a 2-step process.
1. Account owner Alice entitles Bob to transfer up to X tokens from her account A by calling the `icrc2_approve` method on the ledger.
2. Bob can transfer up to X tokens from account A to any account by calling the `icrc2_transfer_from` method on the ledger as if A was Bob's account B.
   The number of transfers Bob can initiate from account A is not limited as long as the total amount spent is below X.

Approvals are not transitive: if Alice approves transfers from her account A to Bob's account B, and Bob approves transfers from his account B to Eva's account E, Eva cannot withdraw tokens from Alice's account through Bob's approval.

## Motivation

The approve-transfer-from pattern became popular in the Ethereum ecosystem thanks to the [ERC-20](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/) token standard.
This interface enables new application capabilities:

  1. Recurring payments.
     Alice can approve a large amount to Bob in advance, allowing Bob to make periodic transfers in smaller installments.
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

This method entitles the `spender` to transfer token `amount` on behalf of the caller from account `{ owner = caller; subaccount = from_subaccount }`.
The number of transfers the `spender` can initiate from the caller's account is unlimited as long as the total amounts and fees of these transfers do not exceed the allowance.
The caller does not need to have the full token `amount` on the specified account for the approval to succeed, just enough tokens to pay the approval fee.
The call resets the allowance and the expiration date for the `spender` account to the given values.

The ledger SHOULD reject the call if the spender account is equal to the source account (`{ owner = caller; subaccount = from_subaccount } == spender`).

If the `expected_allowance` field is set, the ledger MUST ensure that the current allowance for the `spender` from the caller's account is equal to the given value and return the `AllowanceChanged` error otherwise.

The ledger MAY cap the total allowance if it becomes too large (for example, larger than the total token supply).
For example, if there are only 100 tokens, and the ledger receives two approvals for 60 tokens for the same `(owner, spender)` pair, the ledger may cap the total allowance to 100.

```candid "Methods" +=
icrc2_approve : (ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
```

```candid "Type definitions" +=
type ApproveArgs = record {
    from_subaccount : opt blob;
    spender : Account;
    amount : nat;
    expected_allowance : opt nat;
    expires_at : opt nat64;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type ApproveError = variant {
    BadFee : record { expected_fee : nat };
    // The caller does not have enough funds to pay the approval fee.
    InsufficientFunds : record { balance : nat };
    // The caller specified the [expected_allowance] field, and the current
    // allowance did not match the given value.
    AllowanceChanged : record { current_allowance : nat };
    // The approval request expired before the ledger had a chance to apply it.
    Expired : record { ledger_time : nat64; };
    TooOld;
    CreatedInFuture: record { ledger_time : nat64 };
    Duplicate : record { duplicate_of : nat };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};
```

#### Preconditions

* The caller has enough fees on the `{ owner = caller; subaccount = from_subaccount }` account to pay the approval fee.
* If the `expires_at` field is set, it's greater than the current ledger time.
* If the `expected_allowance` field is set, it's equal to the current allowance for the `spender`.

#### Postconditions

* The `spender`'s allowance for the `{ owner = caller; subaccount = from_subaccount }` increases by the `amount` (or decreases if the `amount` is negative).

### icrc2_transfer_from

Transfers a token amount from the `from` account to the `to` account using the allowance of the spender's account (`SpenderAccount = { owner = caller; subaccount = spender_subaccount }`).
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
    spender_subaccount : opt blob;
    from : Account;
    to : Account;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};
```

#### Preconditions
 
 * The allowance for the `SpenderAccount` from the `from` account is large enough to cover the transfer amount and the fees
   (`icrc2_allowance({ account = from; spender = SpenderAccount }).allowance >= amount + fee`). 
   Otherwise, the ledger MUST return an `InsufficientAllowance` error.

* The `from` account holds enough funds to cover the transfer amount and the fees.
  (`icrc1_balance_of(from) >= amount + fee`).
  Otherwise, the ledger MUST return an `InsufficientFunds` error.

 #### Postconditions

 * If the `from` account is not equal to the `SpenderAccount`, the `(from, SpenderAccount)` allowance decreases by the transfer amount and the fees.
 * The ledger debited the specified `amount` of tokens and fees from the `from` account.
 * The ledger credited the specified `amount` to the `to` account.

### icrc2_allowance

Returns the token allowance that the `spender` account can transfer from the specified `account`, and the expiration time for that allowance, if any.
If there is no active approval, the ledger MUST return `{ allowance = 0; expires_at = null }`.

```candid "Methods" +=
icrc2_allowance : (AllowanceArgs) -> (Allowance) query;
```
```candid "Type definitions" +=
type AllowanceArgs = record {
    account : Account;
    spender : Account;
};

type Allowance = record {
  allowance : nat;
  expires_at : opt nat64;
}
```

### icrc1_supported_standards

Returns the list of standards this ledger supports.
Any ledger supporting `ICRC-2` MUST include a record with the `name` field equal to `"ICRC-2"` in that list.

```candid "Methods" +=
icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
```

## Examples

### Alice deposits tokens to canister C

1. Alice wants to deposit 100 tokens on an `ICRC-2` ledger to canister C.
2. Alice calls `icrc2_approve` with `spender` set to the canister's default account (`{ owner = C; subaccount = null}`) and `amount` set to the token amount she wants to deposit (100) plus the transfer fee.
3. Alice can then call some `deposit` method on the canister, which calls `icrc2_transfer_from` with `from` set to Alice's (the caller) account, `to` set to the canister's account, and `amount` set to the token amount she wants to deposit (100).
4. The canister can now determine from the result of the call whether the transfer was successful.
   If it was successful, the canister can now safely commit the deposit to state and know that the tokens are in its account.

### Canister C transfers tokens from Alice's account to Bob's account, on Alice's behalf

1. Canister C wants to transfer 100 tokens on an `ICRC-2` ledger from Alice's account to Bob's account.
2. Alice previously approved canister C to transfer tokens on her behalf by calling `icrc2_approve` with `spender` set to the canister's default account (`{ owner = C; subaccount = null }`) and `amount` set to the token amount she wants to allow (100) plus the transfer fee.
3. During some update call, the canister can now call `icrc2_transfer_from` with `from` set to Alice's account, `to` set to Bob's account, and `amount` set to the token amount she wants to transfer (100 plus the transfer fee).
4. Once the call completes successfully, Bob has 100 extra tokens on his account, and Alice has 100 (plus the fee) tokens less in her account.

### Alice removes her allowance for canister C

1. Alice wants to remove her allowance of 100 tokens on an `ICRC-2` ledger for canister C.
2. Alice calls `icrc2_approve` on the ledger with `spender` set to the canister's default account (`{ owner = C; subaccount = null }`) and `amount` set to 0.
3. The canister can no longer transfer tokens on Alice's behalf.

### Alice atomically removes her allowance for canister C

1. Alice wants to remove her allowance of 100 tokens on an `ICRC-2` ledger for canister C.
2. Alice calls `icrc2_approve` on the ledger with `spender` set to the canister's default account (`{ owner = C; subaccount = null }`), `amount` set to 0, and `expected_allowance` set to 100 tokens.
3. If the call succeeds, the allowance got removed successfully.
   An `AllowanceChanged` error would indicate that canister C used some of the allowance before Alice's call completed.

<!--
```candid ICRC-2.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->
