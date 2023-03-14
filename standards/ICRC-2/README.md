# `ICRC-2`: Approve and Transfer From

| Status |
|:------:|
| Draft  |

## Abstract

`ICRC-2` is an extension of the base `ICRC-1` standard.
`ICRC-2` specifies a way for an account owner to delegate token transfers to a third party on the owner's behalf.

The approve and transfer-from flow is a 2-step process.
1. Account owner Alice creates an approval for principal Bob to transfer up to X tokens from her account A by calling the `icrc2_approve` method on the ledger.
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

The caller creates an approval with an account `{ owner = caller; subaccount = from_subaccount }` with an amount for a `spender`.
The ledger creates a new approval with the approval-transaction-block-id as the approval-id with the `amount` and `expires_at`.
The ledger creates a new entry in the approvals-map: `Map<(Account,Spender,ApprovalId), Approval{expires_at: args.expires_at, available_allowance: args.amount}>`.
When the expires_at field is set, the ledger cancels the approval-id at the expiration time and any remaining/unspent allowance of that approval allowance expires.
The caller does not need to have the full token `amount` on the specified account for the approval to succeed, just enough tokens to pay the approval fee.
The ledger SHOULD reject the request if the caller is the same principal as the spender (no self-approvals allowed).


```candid "Methods" +=
icrc2_approve : (ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
```

```candid "Type definitions" +=
type ApproveArgs = record {
    from_subaccount : opt blob;
    spender : principal;
    amount : nat;
    expires_at : opt nat64;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type ApproveError = variant {
    BadFee : record { expected_fee : nat };
    // The caller does not have enough funds to pay the approval fee.
    InsufficientFunds : record { balance : nat };
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

* The caller has enough balance on the `{ owner = caller; subaccount = from_subaccount }` account to pay the approval fee.
* The caller is different from the `spender`.
* If the `expires_at` field is set, it's creater than the current ledger time.

#### Postconditions

* The `spender`'s total-allowance for the `{ owner = caller; subaccount = from_subaccount }` increases by the `amount`.

### icrc2_transfer_from

Transfers a token amount from between two accounts.
The ledger draws the fees from the `from` account.
If the caller is the owner of the `from` account, `icrc2_transfer_from` ignores allowances and acts as an `icrc1_transfer`.

When a spender calls `icrc2_transfer_from` for an account:
  1. The ledger looks at the current (unexpired) approvals for that Account-Spender pair, sorts the approvals by expiring-soonest to expiring-latest. 
  2. The ledger makes sure that the sum of the available-allowances of the approvals of step-1 is greater-than or equal-to the `amount` + `fee`.
  3. The ledger makes sure that the Account balance is greater-than or equal-to the `amount` + `fee`.
  3. The ledger goes through the approvals of step-1 and deducts the `amount` + `fee` from the allowances starting at the allowance-expiring-soonest and going one by one until the full `amount` + `fee` is deducted from the total-allowance.

The number of transfers the `spender` can initiate from the caller's account is unlimited as long as the transfer amount + fee is <= the spender's total-allowance for the caller's account && transfer amount + fee <= the token-balance of the caller's account. 
The `spender` can make a `icrc2_transfer_from` as long as the account-balance is >= `amount` + `fee` and as long as the `amount` + `fee` of a transfer does not exceed the sum of the current (unexpired) allowances of that Account-Spender pair at the time of the transfer.



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
 
 * If the caller is not the `from` account owner, the caller's total-allowance for the `from` account is large enough to cover the transfer amount and the fees.
   Otherwise, the ledger MUST return an `InsufficientAllowance` error.

* The `from` account holds enough funds to cover the transfer amount and the fees.
  Otherwise, the ledger MUST return an `InsufficientFunds` error.

#### Postconditions

 * If the caller is not the `from` account owner, caller's total-allowance for the `from` account decreases by the transfer amount and the fees.
 * The ledger debited the specified `amount` of tokens and fees from the `from` account.
 * The ledger credited the specified `amount` to the `to` account.

### icrc2_allowances

Returns the allowances that the `spender` can transfer from the specified `account`, and the expiration times for those allowances, if any.
Returns the total-allowance for the `account`-`spender` pair. The total-allowance is the sum of the current (unexpired) allowances of the account-spender pair.
Returns the `latest_approval_id` for the `account`-`spender` pair.
Returns the allowance, expiration, and id of the current (unexpired) approvals for the `account`-`spender` pair starting from the earliest approval or from the `start` if set. 
The ledger may return a subrange of the current approvals because of message size limits. Use the `latest_approval_id` to know when the ledger returns the last approval-allowance.
If there are no active approvals, the ledger MUST return `total_allowance` : 0.

```candid "Methods" +=
icrc2_allowances : (AllowancesArgs) -> (AllowancesData) query;
```
```candid "Type definitions" +=
type AllowancesArgs = record {
    account : Account;
    spender : principal;
    start : opt nat; // if set, the ledger returns the allowances with approval-ids greater-than or equal-to `start` 
};

type AllowancesData = record {
    latest_approval_id : opt nat;
    total_allowance : nat;
    allowances : vec Allowance;
};

type Allowance = record {
  approval_id: nat;
  allowance : nat;
  expires_at : opt nat64;
};
```

### icrc2_cancel_approval

Cancels an approval by an approver.
The approver calls `icrc2_cancel_approval` with the approval-id.

```candid "Methods" +=
icrc2_cancel_approval : (nat) -> (variant { Ok : nat; Err : CancelApprovalError });
```

```candid "Type definitions" +=
type CancelApprovalError = variant {
    ApprovalNotFound;
    CallerIsNotTheApprover;
    ApprovalIsExpired;
    ApprovalIsCanceled : record { cancellation: nat; };
};

```

#### Preconditions
  
 * The approval-id must be an id of an approval-transaction.
  Otherwise, the ledger MUST return an `ApprovalNotFound` error.
 
 * The caller must be the Account owner of the approval.
   Otherwise, the ledger MUST return an `CallerIsNotTheApprover` error.
    
 * The approval must not be expired.
  Otherwise, the ledger MUST return an `ApprovalIsExpired` error.

 * The approval must not have been previously canceled.
  Otherwise, the ledger MUST return an `ApprovalIsCanceled` error with the cancellation block-id.

#### Postconditions

 * The approval-id is now canceled and any remaining allowance of the approval-id is nullified.

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
4. Depending on the result of the call, Bob now has 100 tokens in his account, and Alice has (100 tokens plus the transfer fee) less in her account.

### Alice wants to cancel her approval for a canister

1. Alice wants to cancel her approval of 100 tokens on an `ICRC-2` ledger for a canister.
2. Alice calls `icrc2_cancel_approval` on the ledger with the approval-id of the approval she wants to cancel.
3. The canister can no longer transfer the allowance of the approval on Alice's behalf.

<!--
```candid ICRC-2.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->
