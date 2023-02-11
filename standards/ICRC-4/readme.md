# `ICRC-4`: Batch Transfers

| Status |
|:------:|
| Draft  |

## Abstract

`ICRC-4` is an extension of the base `ICRC-1` standard.
`ICRC-4` specifies a way for an account owner to transfer tokens to multiple addresses in one ledger call in order to drastically reduce the latency of multi account transactions.

The ICRC-4 interface is a generalized interface for submitting multiple transactions in one Internet computer call to an ICRC-1 ledger. It makes no guarantees about the atomicity of the execution of the items, but does outline convinience parameters and the data return in such away that the caller can self verify the results of the transactions.

The interface allows a principle to supply a set of transactions that move tokens from one of their sub accounts to another account. There is no restrictions on which sub accounts, or how many sub accounts can be used, but it is assumed that the principal has the rights to all the sub accounts provided. if the user runs out of funds in any of those sub accounts during the course of the batch being executed, the remaining transactions will fail. 
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

Entitles the `spender` to transfer an additional token `amount` on behalf of the caller from account `{ owner = caller; subaccount = from_subaccount }`.
The number of transfers the `spender` can initiate from the caller's account is unlimited as long as the total amounts and fees of these transfers do not exceed the allowance.
The caller does not need to have the full token `amount` on the specified account for the approval to succeed, just enough tokens to pay the approval fee.
The `spender`'s allowance for the account increases or decreases by the `amount` depending on the sign of the `amount` field. 
If the `expires_at` field is not null, the ledger resets the approval expiration time to the specified value.

The ledger SHOULD reject the request if the caller is the same principal as the spender (no self-approvals allowed).

The ledger MAY cap the total allowance if it becomes too large (for example, larger than the total token supply).
For example, if there are only 100 tokens, and the ledger receives two approvals for 60 tokens for the same `(account, principal)` pair, the ledger may cap the total allowance to 100.

```candid "Methods" +=
icrc2_approve : (ApproveArgs) -> (variant { Ok : nat; Err : ApproveError });
```

```candid "Type definitions" +=
type ApproveArgs = record {
    from_subaccount : opt blob;
    spender : principal;
    amount : int;
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

* The caller has enough fees on the `{ owner = caller; subaccount = from_subaccount }` account to pay the approval fee.
* The caller is different from the `spender`.
* If the `expires_at` field is set, it's creater than the current ledger time.

#### Postconditions

* The `spender`'s allowance for the `{ owner = caller; subaccount = from_subaccount }` increases by the `amount` (or decreases if the `amount` is negative).
  If the total allowance is negative, the ledger MUST reset the allowance to zero.

### icrc2_transfer_from

Transfers a token amount from between two accounts.
The ledger draws the fees from the `from` account.
If the caller is the owner of the `from` account, `icrc2_transfer_from` ignores allowances and acts as an `icrc1_transfer`.

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
 
 * If the caller is no the `from` account owner, the caller's allowance for the `from` account is large enough to cover the transfer amount and the fees.
   Otherwise, the ledger MUST return an `InsufficientAllowance` error.

* The `from` account holds enough funds to cover the transfer amount and the fees.
  Otherwise, the ledger MUST return an `InsufficientFunds` error.
 #### Postconditions

 * If the caller is not the `from` account owner, caller's allowance for the `from` account decreases by the transfer amount and the fees.
 * The ledger debited the specified `amount` of tokens and fees from the `from` account.
 * The ledger credited the specified `amount` to the `to` account.

### icrc2_allowance

Returns the token allowance that the `spender` can transfer from the specified `account`, and the expiration time for that allowance, if any.
If there is no active approval, the ledger MUST return `0`.

```candid "Methods" +=
icrc2_allowance : (AllowanceArgs) -> (Allowance) query;
```
```candid "Type definitions" +=
type AllowanceArgs = record {
    account : Account;
    spender : principal;
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
 
