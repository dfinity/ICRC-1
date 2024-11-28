| Status |
|:------:|
|Draft|

# ICRC-106: Standard for Associating Index Canisters with ICRC-1 Tokens

## 1. Introduction

Wallet applications and token management tools often need to retrieve both token metadata and transaction history for a given principal. However, identifying an associated index canister for ICRC-1 tokens is currently unstandardized, leading to inconsistencies in wallet integrations.

Standard **ICRC-106** :
1. Introduces a standard approach for indicating the presence of an index canister for ICRC-1 tokens through ledger metadata.
2. Defines a minimal interface for the associated index canister to facilitate querying transaction history in a consistent manner.

This draft standard aims to improve interoperability, simplify wallet integrations, and enable token-related applications to reliably access transaction histories.  It acts as a placeholder and documentation source until a more comprehensive standard for index canisters will be developed.


## 2. Metadata

A ledger implementing ICRC-106 MUST include the following entry in the output of the `icrc1_supported_standards` method:

```candid
record { name = "ICRC-106"; url = "https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-106" }
```

Additionally, the ledger MUST provide the following metadata entry retrievable via the `icrc1_metadata` method:

- `icrc106:index_principal` (text): The textual representation of the principal of the associated index canister.

These metadata entries allow clients to discover and interact with the index canister associated with a ledger and can be retrieved using method `icrc1_metadata` defined by the ICRC-1 standard.


Compliant ledgers MUST also implement the following endpoint for programmatically retrieving the index principal:

```candid
icrc106_get_index_principal: () -> (principal) query;
```

The metadata entry `icrc106:index_principal` and the `icrc106_get_index_principal` method MUST provide consistent information. Specifically:

- The `icrc106:index_principal` metadata entry MUST represent the textual form of the principal returned by the `icrc106_get_index_principal` method.  
- The `icrc106_get_index_principal` method MUST return the principal corresponding to the index canister associated with the ledger, as specified in the `icrc106:index_principal` metadata entry.

This requirement ensures that both mechanisms reliably point to the same index canister.


## 3. Index Canister Interface

The index canister associated with the ledger SHOULD implement the following minimal Candid interface:

```candid
type Tokens = nat;

type BlockIndex = nat;

type SubAccount = blob;

type Account = record {
    owner: principal;
    subaccount: opt SubAccount;
};

type GetAccountTransactionsArgs = record {
    account: Account;
    start: opt BlockIndex; // The block index of the last transaction seen by the client.
    max_results: nat; // Maximum number of transactions to fetch.
};

type Burn = record {
    from : Account;
    memo : opt blob;
    created_at_time : opt nat64;
    amount : Tokens;
    spender : opt Account;
};

type Mint = record {
  to : Account;
  memo : opt blob;
  created_at_time : opt nat64;
  amount : Tokens;
};

type Transfer = record {
    to : Account;
    fee : opt Tokens;
    from : Account;
    memo : opt blob;
    created_at_time : opt nat64;
    amount : Tokens;
    spender : opt Account;
};

type Approve = record {
    fee : opt Tokens;
    from : Account;
    memo : opt blob;
    created_at_time : opt nat64;
    amount : Tokens;
    expected_allowance : opt nat;
    expires_at : opt nat64;
    spender : Account;
};

type Transaction = record {
    burn : opt Burn;
    kind : text;
    mint : opt Mint;
    approve : opt Approve;
    timestamp : nat64;
    transfer : opt Transfer;
};

type TransactionWithId = record {
    id : BlockIndex;
    transaction : Transaction;
};

type GetTransactions = record {
  balance : Tokens;
  transactions : vec TransactionWithId;
  // The txid of the oldest transaction the account has
  oldest_tx_id : opt BlockIndex;
};

type GetTransactionsErr = record {
  message : text;
};

type GetAccountTransactionsResult = variant {
  Ok : GetTransactions;
  Err : GetTransactionsErr;
};

type ListSubaccountsArgs = record {
    owner: principal;
    start: opt SubAccount;
};

type Status = record {
    num_blocks_synced : BlockIndex;
};

service : {
    get_account_transactions: (GetAccountTransactionsArgs) -> (GetAccountTransactionsResult) query;
    ledger_id: () -> (principal) query;
    list_subaccounts : (ListSubaccountsArgs) -> (vec SubAccount) query;
    status : () -> (Status) query;
}
```



# Methods Provided by the Index Canister

The index canister provides methods to facilitate querying of transaction history and metadata associated with accounts. Below is a description of the relevant methods specified in this standard, including their purpose, input, output, and typical use case.

---

## get_account_transactions
- **Purpose**: Retrieves transactions associated with a specific account, starting from a specified block index and returning up to a maximum number of results. Transactions are returned in **reverse chronological order** (newest to oldest).
- **Input**:
  - `account`: The account (principal and optional subaccount) for which transactions are to be fetched.
  - `start`: *(Optional)* The block index of the most recent transaction the client has already seen. If provided, only transactions with block indices **less than** this value will be returned.
  - `max_results`: The maximum number of transactions to return.
- **Output**:
  - **`Ok`**: Returns a record containing:
    - `balance`: The current token balance of the account.
    - `transactions`: A vector of `TransactionWithId`, each containing:
      - `id`: The block index of the transaction.
      - `transaction`: Details of the transaction (burn, transfer, approval, and timestamp).
    - `oldest_tx_id`: *(Optional)* The block index of the oldest transaction for the account, or `None` if no transactions exist.
- **Typical Use Case**: This method is often used by wallets to display transaction history and update account balances. It also supports paginated transaction retrieval for efficient history browsing.

---

## list_subaccounts
- **Purpose**: Lists all subaccounts associated with a specified principal.
- **Input**:
  - `owner`: The principal for which to list subaccounts.
  - `start`: *(Optional)* Specifies the subaccount to start listing from. Only subaccounts lexicographically greater than `start` will be included. If start is omitted, the method will return all subaccounts from the beginning of the list, ordered lexicographically.
- **Output**: A vector of `SubAccount`, each representing a subaccount under the specified principal. The list will be empty if the principal has not used subaccounts, or if there are no subaccounts lexicographically higher than `start`.
- **Typical Use Case**: Useful for wallets or tools that need to enumerate *all* subaccounts associated with a user. To get all subaccounts, start with no start parameter and repeatedly call the method, updating start with the last subaccount from each response, until the returned list is empty.


---

## ledger_id
- **Purpose**: Retrieves the principal of the ledger canister that the index is linked to.
- **Input**: None.
- **Output**: The `principal` of the ledger canister.
- **Typical Use Case**: This method is primarily used for validating the relationship between the index and the ledger, ensuring they are correctly linked, and facilitating integrations requiring the ledger’s identity.


---

## status
- **Purpose**: Retrieves the synchronization and operational status of the index canister.
- **Input**: None.
- **Output**: A `Status` record containing:
  - `num_blocks_synced`: The total number of blocks that have been successfully synchronized by the index canister.
- **Typical Use Case**: Used for monitoring the health and synchronization status of the index, this method is helpful for determining whether the index has fully caught up with the ledger and is operational.


## Optional Methods

While the methods defined in this standard are sufficient for compliance with ICRC-106, certain implementations of the index canister may include additional methods to extend functionality. These methods are not required by ICRC-106 but may be present for advanced use cases:

- **`get_blocks`**: Fetches raw block data for a specified range of indices. This is useful for applications requiring detailed historical data.
- **`get_fee_collectors_ranges`**: Provides detailed information about fee collection, including accounts and associated block ranges.
- **`icrc1_balance_of`**: Queries the token balance of specific accounts. This method is commonly used for token management in wallets and tools.

These methods, while potentially helpful, are outside the scope of ICRC-106 and are not guaranteed to be present in all index canisters. Developers should refer to the documentation of the specific implementation they are working with for details on these optional methods.




## 4. Implementation Considerations

Implementers should ensure that:
- The `icrc106:index_principal` metadata entry accurately reflects the principal of the associated index canister.
- Any changes to the index canister interface should maintain backward compatibility.

By adhering to ICRC-106, ledger canisters provide a standardized mechanism for clients to discover and interact with their associated index canisters, improving integration and user experience within the Internet Computer ecosystem.
