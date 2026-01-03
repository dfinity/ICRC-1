# ICRC-2 Advisory

This document provides clarifications and implementation guidance for the
ICRC-2 standard based on findings from a security review.

The intent of this advisory is to make explicit certain behaviors that are
underspecified in the ICRC-2 specification, in order to reduce ambiguity for
ledger implementers and client developers. This document does not change the
normative requirements of ICRC-2, but clarifies expectations and highlights
recommended practices.

---

## 1. Transaction Deduplication

### Clarification

ICRC-2 methods (`approve` and `transfer_from`) include arguments and error
variants (`created_at_time`, `memo`, `Duplicate`, `TooOld`) that imply support
for transaction deduplication and replay protection.

This advisory clarifies the expected deduplication behavior for ICRC-2
operations.

### Advisory Guidance

Ledger implementations SHOULD implement transaction deduplication for
`approve` and `transfer_from` according to the following rules:

#### Transaction Identity

- A transaction is identified by the combination of:
  - the caller,
  - the method name (`approve` or `transfer_from`),
  - the full set of method arguments, including `created_at_time` and `memo`
    if provided.

- Two calls with identical transaction identity are considered duplicates.

#### Time Window

- If `created_at_time` is provided:
  - The ledger SHOULD reject calls whose `created_at_time` is too far in the
    past or too far in the future relative to the ledger’s current time,
    returning a `TooOld` error.
  - The ledger SHOULD define and document the accepted time window.

- If `created_at_time` is not provided:
  - The ledger MAY treat each call as unique, or
  - MAY apply ledger-specific policies; such behavior SHOULD be documented.

#### Duplicate Handling

- If a call is determined to be a duplicate of a previously processed
  transaction:
  - The ledger SHOULD reject the call and return a `Duplicate` error.
  - The ledger MUST NOT apply the transaction effects again.
