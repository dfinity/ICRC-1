| Status |
|:------:|
|Draft|

# ICRC-191: Enhanced Allowance Query Mechanism with Pagination

## 1. Introduction

Although calls to the `icrc2_approve` and `icrc2_transfer_from` methods are recorded in the ledger, it is not possible to determine the allowances that are in effect at some point in time, except by traversing the entire ledger.  This standard introduced an endpoint which will return this information thus making the management of allowances feasible.

ICRC-191 is an extension of the ICRC-2 standard.  
ICRC-191 specifies a way to list outstanding allowances.


## 2. Metadata
The endpoint introduced in this standard operates in two ways.  In the public version any principal can obtain the outstanding allowances of any other principal. In the private version, the allowances returned by the endpoint must have been issued by the caller (i.e. the caller is the principal controlling the source account of an allowance.)
Which version of the standard is implemented by a ledger is specified through metadata which can be retrieved using `icrc1_metadata`.

A ledger that implements ICRC-191 MUST return metadata `icrc191:public` of type Text (optional). The possible values are `true` if the allowance data is public and `false` otherwise.

## 3. Specification

## 4. Semantics
- Explanation of how certain elements, like `from_owner` and pagination, function within the standard.

## 6. Example Using Symbolic Values
- A detailed example illustrating the behavior of the `list_icrc2_allowances` method with symbolic values.
