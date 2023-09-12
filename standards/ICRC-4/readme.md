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
    BadBatchFee : record { expected_fee : nat };
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

* The caller has enough fees on the `{ owner = caller; subaccount = from_subaccount }` account to pay the transfer fees required by the application. The application is free to determine the fee schema. It MAY require a batch fee and it MAY require a fee on each tranaaction.
* The caller has included at or below the max_transactions in the request.
* If pre_validate is true then all transactions included in the batch will pass validation before any are processed.  If any transaction does not pass pre_validation then no transactions will be processed.


#### Postconditions

* The accounts are updated with a new balance unless the pre_validate was requested and failed.
* The results of each transaction are paired with the original request arguments. Ordering is not guaranteed.
* If prevalidate fails, the triggering error should be indicated by the TransferBatchError. Only the first, triggering error is returned.

#### Application Specific Conditions

* The batch_fee is optional, it indicates the max batch fee the users is willing to pay for the entire batch. If the application requires a larger fee, it shold fail with a BadBatchFee error.
* The order of transaction processing will be decided by the application, including, but not limited to, any async processing that may be required.

### query icrc4_balance_of_batch

Allows anyone to query the ballance of a set of accounts.

```candid "Methods" +=
icrc4_balance_of_batch : ([Account]) -> (record{ 
    Ok: [(Account,nat)]; 
    Err: BalanceBatchError) query;
    });
```

```candid "Type definitions" +=
type TransferBatchError = variant {
    TooManyBalances : record { max : nat };
};
'
```

#### Preconditions
 
 * The number of accounts must be below max_balances in the request
 #### Postconditions

 * Accounts are provide in an array with the original request associated with request such that ordering of request and response does not need to be synced.

### query icrc4_validate_batch

Validates a batch of transactions.  Returns Ok if the transactions pass the pre_validate conditions.  If an Error is returned it should be the first error that triggerd a failure

```candid "Methods" +=
icrc4_validate_batch: (ValidateBatchArgs) -> (variant { Ok : (); Err : TransferBatchError }) query;
```

```candid "Type definitions" +=
type ValidateBatchArgs = record {
    transactions : [TransferArgs];
    batch_fee : opt nat;
};

```

#### Application Specific Conditions

* The batch_fee is optional. If provided the users should expect the application to validate that the batch fee provided will pass.

### icrc 4 metadata fields to add to icrc1 metadata field.


```

    "icrc4_max_transactions" : #Nat
    "icrc4_max_balances"  : #Nat
    "icrc4_batch_fee" : #Nat

type Value = variant {
    Nat : nat;
    Int : int;
    Text : text;
    Blob : blob;
};

service : {
    icrc1_metadata : () -> (vec record { text; Value; }) query;
}


```

#### Details

* max_transactions indicates the maximum transactions allowed per batch.
* max_balances indicates the maximum query balances allowed per batch.
* batch_fee indicates a minimum required batch fee if required.

### icrc1_supported_standards

Returns the list of standards this ledger supports.
Any ledger supporting `ICRC-4` MUST include a record with the `name` field equal to `"ICRC-4"` in that list.

```candid "Methods" +=
icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
```

## Examples


<!--
```candid ICRC-2.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->
 
