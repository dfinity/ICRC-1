# `ICRC-4`: Batch Transfers

| Status |
|:------:|
| Draft  |

## Abstract

`ICRC-4` is an extension of the base `ICRC-1` standard.
`ICRC-4` specifies a way for an account owner to transfer tokens to multiple addresses in one ledger call in order to drastically reduce the latency of multi account transactions.

The ICRC-4 interface is a generalized interface for submitting multiple transactions in one Internet computer call to an ICRC-1 ledger. It makes no guarantees about the atomicity of the execution of the items, but does outline convinience parameters and the data return in such away that the caller can self verify the results of the transactions.

The interface allows a principle to supply a set of transactions that move tokens from one of their sub accounts to another account. There is no restrictions on which subaccounts, or how many sub accounts can be used, but it is assumed that the principal has the rights to all the sub accounts provided.

## Motivation

Many contracts provide multiplarty transactions or settlment processes tht may move tokens from any accounts owned by a principal to many other accounts. With the ICRC-1 standard, each of these transactions must be submitted seperatelay and incure both call cylce charge(more if a subnet boundry is crossed) and a latency charge as a contract cannot blindly submit unlimited transactions without awaiting due to cycle limits.

This interface enables new application capabilities:

  1. Send from multiple account to multiple accounts in one transaction.
     Alice can approve a transfer of 10 ICP from her sub-account 1 to Bob and 2 ICP from her sub-account 2 to Charlie.

  2. Check that all transactions are valid befor starting tranfers.
     In some ledgers, transfers are atomic and we can check at the begining that all transactions will pass before performing the transactions.

## Specification

> The keywords "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in RFC 2119.

**Canisters implementing the `ICRC-4` standard MUST implement all the functions in the `ICRC-4` interface**

**Canisters implementing the `ICRC-4` standard MUST include `ICRC-4` in the list returned by the `icrc1_supported_standards` method**

## Methods

```candid "Type definitions" +=
type Account = record {
    owner : principal;
    subaccount : opt blob;
};
```

### icrc4_transfer_batch

Moves tokens from many accounts `{ owner = caller; subaccount = from_subaccount }` to many other accounts.

The ledger MAY cap the total numbr of transactions in one batch as the IC has a current limitation of message size of around 2MB and thus neither outgoing messages or return types should be greater than this. In addition, some ledger may include extensive calculations to balances that could limit the number of processed transactions that may be exdcuted within the cycle limit.

```candid "Methods" +=
icrc4_transfer_batch: (TransferBatchArgs) -> (variant { Ok : [(TransferArg, variant {Ok: Nat, Err: TransferError})]; Err : TransferBatchError });
```

```candid "Type definitions" +=
type TransferBatchArgs = record {
    pre_validate : bool;
    transactions : [TransferArgs];
    batch_fee : opt nat;
};

type TransferArgs = record {
    from_subaccount : opt Subaccount;
    to : Account;
    amount : nat;
    fee : opt nat;
    memo : opt blob;
    created_at_time : opt nat64;
};

type TransferError = variant {
    BadFee : record { expected_fee : nat };
    BadBurn : record { min_burn_amount : nat };
    InsufficientFunds : record { balance : nat };
    TooOld;
    CreatedInFuture : record { ledger_time: nat64 };
    Duplicate : record { duplicate_of : nat };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};

type TransferBatchError = variant {
    TooManyTransactions : record { max : nat };
    BadBurn : (TransferArg, record { min_burn_amount : nat });
    InsufficientFunds : (TransferArgs, record { balance : nat });
    TooOld: TransferArgs;
    CreatedInFuture : (TransferArg, record { ledger_time: nat64 });
    Duplicate : (TransferArg, record { duplicate_of : nat });
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};


```

#### Preconditions

* The caller has enough fees on the `{ owner = caller; subaccount = from_subaccount }` account to pay the transfer fees.
* The caller has included at or below the max_transactions in the request.

#### Postconditions

* The accounts are updated with a new balance unless the pre_validate was requested and failed.

### query icrc4_balance_of_batch

Allows anyone to query the ballance of a set of accounts.

```candid "Methods" +=
icrc4_balance_of_batch : ([Account]) -> (record{ Ok: [(Account,nat)]; Err: BalanceBatchError);
```

```candid "Type definitions" +=
type TransferBatchError = variant {
    TooManyBalances : record { max : nat };
};

#### Preconditions
 
 * The number of accounts must be below max_balances in the request
 #### Postconditions

 * Accounts are provide in an array with the original request associated with request such that ordering of request and response does not need to be synced.

### icrc4_metadata

Returns the metadata for the ICRC-4 specification.

```candid "Methods" +=
icrc4_metatdata : () -> (ICRC4Metada) query;
```
```candid "Type definitions" +=
type ICRC4Metada = record {
    max_transactions : opt nat;
    max_balances : opt nat;
    batch_fee: opt nat;
};

```
### icrc1_supported_standards

Returns the list of standards this ledger supports.
Any ledger supporting `ICRC-4` MUST include a record with the `name` field equal to `"ICRC-4"` in that list.

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
 
