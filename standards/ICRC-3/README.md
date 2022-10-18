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

The transaction type is a record with two required fields:
  1. The `kind` field contains the transaction type (`icrc1_mint`, `icrc1_burn`, `icrc1_transfer`, etc.).
  2. The `timestamp` field contains the IC time at which the ledger accepted the transaction.
All other fields are optional and correspond to different transaction types.

The value of the `kind` field determines which field in the transaction record has a value.
For example, if `kind = "icrc1_transfer"`, then the `icrc1_transfer` field contains the transaction details.

> **Note**
> One of the reasons we use record to emulate a transaction variant is that as of October 2022, Candid does not support extensible variants.
> See https://github.com/dfinity/candid/issues/295 for more detail.

```candid "Type definitions" +=
type Account = record { owner : principal; subaccount : opt blob; };

type Transaction = record {
     kind : text; // "icrc1_mint" | "icrc1_burn" | "icrc1_transfer" | ...
     icrc1_mint : opt record {
         amount : nat;
         to : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     icrc1_burn : opt record {
         amount : nat;
         from : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     icrc1_transfer : opt record {
         amount : nat;
         from : Account;
         to : Account;
         memo : opt blob;
         created_at_time : opt nat64;
     };
     timestamp : nat64;
};
```

The client specifies the index of the first transaction and the number of transactions to fetch.

The ledger returns a record with the following fields:
  * The `log_length` field is the total number of transactions in the log.
  * The `transactions` field is an _infix_ of the requested transaction range.
  * The `first_index` field is the index of the first transaction in the `transaction` field.
    If the `transactions` field is an empty vector, the value of `first_index` is unspecified.
  * The `archived_transactions` field contains instructions for fetching the _prefix_ of the requested range.
    Each entry indicates that the client can fetch transactions in the range `[start, length]` with the specified `callback` method reference.

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
All transaction ranges that `{ start; length }` tuples in the `archived_transactions` field form MUST have a non-zero intersection with the requested range.

```candid "Type definitions" +=
type QueryArchiveFn = func (GetTransactionsRequest) -> (TransactionRange) query;

type TransactionRange = record { transactions : vec Transaction; };
```

Ledger and archives MAY return fewer transactions than the client requested.

## Examples

### Synchronizing the state

The following example demonstrates how a client can synchronize with the ledger state distributed across multiple canisters using the proposed interface.

  1. The client calls `icrc3_get_transactions({ start = 0; length = 10_000 })` on the ledger.
  2. The ledger has 9_500 transactions and happens to have transactions `4_000..5_500` in memory.
     However, the ledger implementors decided not to return more than 1_000 per request.
  3. The ledger returns the following value.
     ```candid
     record {
        log_length = 5_500;
        transactions = vec { /* transactions 4_000..5_000 */ };
        first_index = 4_000;
        archived_transactions = vec {
            record { start = 0; length = 4_000; callback = "4kydj-ryaaa-aaaag-qaf7a-cai"."get_archived_transactions" }
        }
     }
     ```
  4. The client appends transactions `4_000..5_000` to the local buffer and issues a follow-up call to the archive: `get_archived_transactions({ start = 0; length = 4_000 })`.
  5. The archive implementors decided not to return more than 2_000 transactions per request.
     The archive returns the following value.
     ```candid
     record { transactions : vec { /* transactions 0..2_000 */ } }
     ```
  6. The client appends transactions `0..2_000` to the buffer.
     Since the archive returned fewer blocks than requested, the client repeats the call with a different range: `get_archived_transactions({ start = 2_000; length = 2_000 })`.
  7. The archive returns the following value.
     ```candid
     record { transactions : vec { /* transactions 2_000..4_000 */ } }
     ```
  8. The client appends transactions `2_000..4_000` to the buffer.
     Since there are more transactions to fetch according to the `log_length` value, the client makes a follow-up call to the ledger: `icrc3_get_transactions({ start = 5_000; length = 1_000 })`.
  9. The ledger accepted a hundred more transactions in the meantime and archived transactions `4_000..5_000`.
     It returns the following value:
     ```candid
     record {
        log_length = 5_600;
        transactions = vec { /* transactions 5_000..5_600 */ };
        first_index = 5_000;
        archived_transactions = vec {};
     }
     ```
  10. The client adds transactions `5_000..5_600` to the buffer.
      It is synced with the ledger now.

<!--
```candid ICRC-3.did +=
<<<Type definitions>>>

service : {
  <<<Methods>>>
}
```
-->