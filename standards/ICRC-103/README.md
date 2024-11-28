| Status |
|:------:|
|Draft|

# ICRC-103: Enhanced Allowance Query Mechanism with Pagination

## 1. Introduction

The `icrc2_allowance` method can be used to get the allowance between specific pairs of accounts on the ledger. However, retrieving all allowances associated with a principal is challenging because it requires knowledge of the various subaccounts and spender information linked to that principal. Additionally, while calls to the `icrc2_approve` and `icrc2_transfer_from` methods are recorded in the ledger, determining which allowances are currently in effect would require traversing the entire ledger. This standard addresses these challenges by introducing an endpoint that allows querying all outstanding allowances related to a specific account, thus facilitating comprehensive and efficient allowance management.




ICRC-103 is an extension of the ICRC-2 standard.  
ICRC-103 specifies a way to list outstanding allowances.


## 2. Metadata

A ledger that implements ICRC-103 MUST include `record {name = "ICRC-103"; url = ""https://github.com/dfinity/ICRC/blob/main/ICRCs/ICRC-106""}` as part of the output of `icrc1_supported_standards`.

The endpoint introduced in this standard operates in two ways.  In the public version any principal can obtain the outstanding allowances of any other principal. In the private version, the allowances returned by the endpoint must have been issued by the caller (i.e. the caller is the principal controlling the source account of an allowance.)
Which version of the standard is implemented by a ledger is specified through the `icrc103:public_allowances` metadata.

A ledger that implements ICRC-103 MUST return the metadata entry `icrc103:public_allowances` of type `text`. The possible values are "true" if the allowance data is public and "false" otherwise.

The number of allowances that the ledger can return in response to a query is limited by an implementation-specific maximum, specified through the `icrc103:max_take_value` metadata.

A ledger that implements ICRC-103 MUST return the metadata entry `icrc103:max_take_value` of type `nat`, indicating the precise maximum number of allowances the ledger will return in response to a query.

Metadata entries can be retrieved using method `icrc1_metadata` defined by the ICRC-1 standard.

## 3. Methods

Some of the types used are shared with standards ICRC-1 and ICRC-2; we restate their definition for completeness.

```candid
icrc103_get_allowances : (GetAllowancesArgs) -> (variant{Ok: Allowances, Err: GetAllowancesError}) query

type GetAllowancesArgs = record {
    from_account : opt Account;
    prev_spender : opt Account;
    take : opt nat;
}

type GetAllowancesError = variant{
    AccessDenied : text;
    GenericError : record { error_code : nat; message : text };
}


type Allowances = vec record {
    from_account : Account;
    to_spender : Account;
    allowance : nat;
    expires_at : opt nat64;
}

type Account = record {
    owner : principal;
    subaccount : opt blob;
};

```

The endpoint returns up to `take` allowances belonging to from_account.owner, starting with the allowance between `from_account` and `prev_spender`.


## 4. Semantics

Outstanding allowances, as specified in the ICRC-2 standard, are represented as a map from pairs of accounts to allowances. To specify the behavior of `icrc103_get_allowances`, the set of pairs `(Account, Account)` is ordered lexicographically. Let `first_subaccount` be the lexicographically first subaccount (the default subaccount, i.e., the all-0 32-byte string). Let `caller_principal` be the principal of the caller.

The `icrc103_get_allowances` method behaves as follows:

* If `from_account` is not provided, it is instantiated as `Account{caller_principal, first_subaccount}`.  
* If `from_account.subaccount` is not provided, it is instantiated with `first_subaccount`.

If the ledger implements the private version of the standard, the endpoint returns an `AccessDenied` if `from_account.owner ≠ caller_principal`.

Otherwise, the endpoint returns a list of records of the form `(account_1, account_2, allowance)` in lexicographic order, with `account_1.owner = from_account.owner`.
 * If `prev_spender` is provided the list starts with the allowance immediately succeeding `(from_account, prev_spender)`.
 * If `prev_spender` is not provided the list starts with the first allowance from `from_account`.

The list includes up to `take` entries if `take` is provided, but it cannot exceed the maximum number specified by the `icrc103:max_take_value` metadata. If `take` is not provided, the ledger will return as many entries as possible, up to the limit specified by `icrc103:max_take_value`.

If the response contains fewer entries than the smaller of `take` and `icrc103:max_take_value`, it indicates that there are no more allowances that meet the criteria for listing.

## 5. Example Using Symbolic Values

Assume that the ledger stores the following allowances, listed in lexicographic order. Below, `p0,p1,...,p5` are some arbitrary principals, `s0` is the default subaccount, `s1,s2,..,s5` are subaccounts, and `a1,a2,...,a5` are allowances (the associated expiration is omitted).

- **A1** = `((p0, s0), (p1, s1), a1)`
- **A2** = `((p0, s0), (p2, s2), a2)`
- **A3** = `((p0, s1), (p3, s3), a3)`
- **A4** = `((p1, s1), (p4, s4), a4)`
- **A5** = `((p1, s2), (p5, s5), a5)`

Each entry in the list is of the type `(from_account: (<principal>,<subaccount>), to_spender: (<principal,subaccount>), <allowance>)`

Then:


1. **Case 1: `prev_spender` is not provided**
   - If `p0` calls the get allowances endpoint with `from_account = (p0, s0)`, `prev_spender = None`, and `take = 4`, the endpoint returns `(A1, A2, A3)`.
     - Since `prev_spender` is not provided, the list starts with the first allowance from `from_account = (p0, s0)`.
     - The endpoint returns allowances for `p0`, including those that may not originate from `(p0, s0)`.

2. **Case 2: `prev_spender` is provided**
   - If `p0` calls the get allowances endpoint with `from_account = (p0, s0)`, `prev_spender = (p1, s1)`, and `take = 3`, the endpoint returns `(A2, A3)`.
     - Since `prev_spender = (p1, s1)` is provided, the list starts with the first allowance immediately succeeding `(p0, s0), (p1, s1)` in lexicographic order, which is `(p0, s0), (p2, s2)` (A2).
     - The returned list contains only allowances where the `owner` of `account_1` is `p0`, which matches the `from_account.owner`.

3. **Case 3: Private version of the standard**
   - If `p0` calls the get allowances endpoint with `from_account = (p1, s0)` (`p0 ≠ p1`), and the ledger implements the private version of the standard, the endpoint returns an empty list.
     - Since `from_account.owner ≠ caller_principal` and the ledger implements the private version, no allowances are returned.

4. **Case 4: `prev_spender` is not in the list**
   - If `p0` calls the get allowances endpoint with `from_account = (p0, s0)`, `prev_spender = (p2, s)` for some `s1 < s < s2`, and `take = 2`, the endpoint returns `(A2, A3)`.
     - Since `(p0, s0), (p2, s)` is not in the list, the allowances start with the first available pair greater than `(p0, s0), (p2, s)`—in this case, `(p0, s0), (p2, s2)` (A2).
