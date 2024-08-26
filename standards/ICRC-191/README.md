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

Outstanding allowances, as specified in the ICRC-2 standard, are represented as a map from pairs of accounts to allowances. To specify the behavior of `icrc191_list_allowances`, the set of pairs `(Account, Account)` is ordered lexicographically. Let `first_principal` be the lexicographically first principal, and `first_subaccount` be the lexicographically first subaccount (the default subaccount, i.e., the all-0 32-byte string). Let `caller_principal` be the principal of the caller.

The `icrc191_list_allwances` method behaves as follows:

* If `from_account` is not provided, it is instantiated as `Account{caller_principal, first_subaccount}`.  
* If `from_account.subaccount` is not provided, it is instantiated with `first_subaccount`.
* If `prev_spender` is not provided, it is instantiated with `Account{first_principal, first_subaccount}`.

If the ledger implements the private version of the standard, then the endpoint returns the empty list if `from_account.owner ≠ caller_principal`.

Otherwise, the endpoint returns a list of records of the form `(account_1, account_2, allowance)` in lexicographic order, starting with the allowance of `(from_account, prev_spender)` (if present), and where `account_1.owner = from_account.owner`. The list is limited to at most `taken` entries, or some maximum number of entries (that is an internal constant of the ledger).



## 5. Example Using Symbolic Values

Assume that allowances stored at some point by the ledger are, in lexicographic order:

- A1 = ((p0,s0), (p1,s1), a1)
- A2 = ((p0,s0), (p2,s2), a2)
- A3 = ((p0,s1), (p3,s3), a3)
- A4 = ((p1,s1), (p4,s4), a4)
- A5 = ((p1,s2), (p5,s5), a5)

Then:

- If `p0` calls the list allowances endpoint, with `from_account = (p0, s0)`, `prev_spender = None` and `take=4` the endpoint returns (A1, A2, A3), i.e. the endpoint only returns allowances of accounts belonging to `p0`, it is limited to allowances of `p0`, but not only to those having `(p0,s0)` as source of the allowance.

- If `p0` calls the list allowances endpoint with `from_account = (p1,s0)`, `p0 ≠ p1`, and the ledger implements the private version of the endpoint, then the endpoint returns the empty array.

- If `p0` calls the list allowances endpoint with `from_account = (p0,s0)`, `prev_spender = (p2,s)` for some `s1 < s < s2`, and `take = 2` the endpoint returns `A2, A3`, i.e. `(from_account, prev_spender)` is not in the list, the allowances returned start with the first available allowance between a pair of accounts greater than `(from_account, prev_spender)`.
