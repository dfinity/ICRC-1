# ICRC-1 Advisory

The intent of this advisory is to provide additional clarification and
explanation of certain behaviors described in the ICRC-1 specification, to
help avoid potential misinterpretation in implementations.

It focuses on error handling and atomicity for `icrc1_transfer`. This
advisory is non-normative and does not change the ICRC-1 specification.


## Error Semantics and Atomicity

### Clarification

The ICRC-1 specification defines error variants for `icrc1_transfer`, but
does not explicitly state which ledger effects are guaranteed not to occur
when an error is returned.

This advisory clarifies the expected behavior.

### Advisory Guidance

Ledger implementations SHOULD ensure that `icrc1_transfer` is atomic with
respect to **externally observable ledger effects**, including:

- account balances, and
- the transaction log.

In particular:

- A successful response (`Ok(nat)`) SHOULD imply that all balance updates related
  to the transfer (including debits/credits for the transfer amount, fees, and
  any other charges) and the corresponding transaction log entry have been
  applied.

- An error response SHOULD imply that:
  - no account balances have been modified; and
  - no transaction log entry corresponding to the call has been recorded.

This guidance does not restrict changes to internal or auxiliary ledger
state (e.g., caches, metrics, bookkeeping data, or internal logs).

### Client Considerations

- Clients MAY assume that an error response from `icrc1_transfer` implies no
  externally observable ledger effects.
- Clients SHOULD NOT assume stronger guarantees unless explicitly documented
  by the ledger.

## Scope and Non-Goals

This advisory does not modify the ICRC-1 interface, define new error types, or
constrain internal ledger state.


## Summary

ICRC-1 transfers are expected to be atomic with respect to balances and the
transaction log, and error responses SHOULD not result in any externally
observable ledger effects.

