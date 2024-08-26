| Status |
|:------:|
|Draft|

# ICRC-191: Enhanced Allowance Query Mechanism with Pagination

## 1. Introduction

Although calls to the `icrc2_approve` and `icrc2_transfer_from` methods are recorded in the ledger, it is not possible to determine the allowances that are in effect at some point in time, except by traversing the entire ledger.  This standard introduced an endpoint which will return this information thus making the management of allowances feasible.

ICRC-191 is an extension of the ICRC-2 standard.  
ICRC-191 specifies a way to list outstanding allowances.


## 2. Metadata

A ledger that implements ICRC-191 MUST must include `record {name = "ICRC-191"; url = "https://github.com/dfinity/ICRC-1/standards/ICRC-191"}` as part of the output of `icrc1_supported_standards`.

The endpoint introduced in this standard operates in two ways.  In the public version any principal can obtain the outstanding allowances of any other principal. In the private version, the allowances returned by the endpoint must have been issued by the caller (i.e. the caller is the principal controlling the source account of an allowance.)
Which version of the standard is implemented by a ledger is specified through metadata which can be retrieved using `icrc1_metadata`.

A ledger that implements ICRC-191 MUST return metadata `icrc191:public_allowances` of type Text (optional). The possible values are "true" if the allowance data is public and "false" otherwise.


## 3. Methods

Some of the types used are shared with standards ICRC-1 and ICRC-2; we restate their definition for completeness.

```candid
icrc191_list_allowances : (ListAllowancesArgs) -> (ListAllowancesResult) quey

type ListAllowancesArgs = record {
    from_account : opt Account;
    prev_spender : opt Account;
    take : opt nat;
}

ListAllowanceResult = vec record {
    from_account : Account;
    to_spender : Account;
    allowance : Allowance;
}

type Account = record {
    owner : principal;
    subaccount : opt blob;
};

type Allowance = record {
  allowance : nat;
  expires_at : opt nat64;
}
```

The endpoint returns up to `taken` allowances of the from_account.owner, starting with the allowance between `from_account` and `to_account`.


## 4. Semantics

Recall that outstanding allowances are (per the ICRC-2 standard) specified as a map from pairs of accounts, to allowances.  To specify the behavior of icrc191_list_allowances we require that the set of pairs (Account, Account) is ordered, lexicographically.
Let `first_principal` be the lexicographically first principal `first_subaccount` be the lexicographically first subaccount (this is the default subaccount, i.e. the all-0 32 byte string).
Let `caller_principal` be the principal of the caller.


If `from_account` is not provided, then this is instantiated with `Account{caller_principal, first_subaccount}`.  
If `from_account.subaccount` is not specified then this is instantiated with `first_subaccount`.
If `prev_spender` is not specified, then this is instantiated with `Account{first_principal, first_subaccount}`.

The endpoint returns the list of records of the form `(account_1, account_2, allowance), in lexicographic order starting with the allowance of `(from_account, prev_spender).
The list is limited to at most `taken` entries, or some maximum number


## 5. Example Using Symbolic Values
