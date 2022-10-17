# ICRC-3: transaction log interface

| Status |
|:------:|
| Draft  |

## Abstract

The ICRC-3 standard specifies an API for accessing the ledger transaction log, potentially distributed across multiple canisters.

## Motivation

Displaying the list of past transactions is among the most requested features in token wallet applications.
The ICRC-3 standard provides a minimal API providing access to the past transactions recorded on an ICRC-1—compliant ledger.

The following constraints guided the API design:

  1. Extensibility.
     The API must allow the ledger to add new transaction types without breaking existing clients.

  1. Query-only interface.
     Query methods do not modify the canister state, simplifying canister audit significantly.

  1. Memory efficiency.
     The entire transaction log might not fit into the canister memory.
     The proposed API accounts for the case when the ledger shards transactions across multiple canisters.

  1. Canisters as the primary consumers of the interface.
     This interface is not suitable for high-performance off-chain data validation.

## Methods

### icrc3_get_transactions

Returns a list of transactions from the specified range.

```candid "Methods" +=
icrc3_get_transactions : (GetTransactionsRequest) -> (GetTransactionsResponse) query;
```

The ledger identifies transactions by their sequence number.
The ledger creates a transaction for each successful state mutation.

```candid "Type definitions" +=
type TxIndex = nat;
```

Transaction is a record with one required field, `kind`, that contains the transaction type (e.g., "mint", "burn", "transfer", etc.).
The value of the `kind` field determines which other field in the transaction record has a value.
For example, if `kind = "transfer"`, then the `transfer` field contains the transaction details.
All other fields are optional.

```candid "Type definitions" +=
type Account = record { owner : principal; subaccount : opt blob; };

type Transaction = record {
     kind : text;
     mint : opt record {
         amount : nat;
         to : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     burn : opt record {
         amount : nat;
         from : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     transfer : opt record {
         amount : nat;
         from : Account;
         to : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     timestamp : nat64;
};
```

```candid "Type definitions" +=
type GetTransactionsRequest = record { start : TxIndex; length : nat };

type GetTransactionsResponse = record {
    log_length : nat;
    transactions : vec Transaction;
    first_index : TxIndex;
    archived_transactions : vec record {
        start : TxIndex;
        length : nat;
        callback : QueryArchiveFn;
    };
};
```

Some of the transactions in the range might be "archived", i.e., reside in other canisters.

```candid "Type definitions" +=
type QueryArchiveFn = func (GetTransactionsRequest) -> (TransactionRange) query;

type TransactionRange = record { transactions : vec Transaction; };
```


<!--
```candid ICRC-3.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->