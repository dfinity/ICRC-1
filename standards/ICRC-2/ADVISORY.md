# ICRC-2 Advisory

The intent of this advisory is to provide additional clarification and
explanation of certain behaviors described in the ICRC-2 specification, to
help avoid potential misinterpretation in implementations.

It clarifies expectations and the intended meaning, and highlights recommended
practices for transaction deduplication, error semantics and atomicity, and fee
handling for `icrc2_approve` and `icrc2_transfer_from`. This advisory is
non-normative and does not change the ICRC-2 specification.

## 1. Transaction Deduplication

### Clarification

ICRC-2 methods (`icrc2_approve` and `icrc2_transfer_from`) include arguments and error
variants (`created_at_time`, `memo`, `Duplicate`, `TooOld`) that imply support
for transaction deduplication and replay protection.

This advisory clarifies the expected deduplication behavior for ICRC-2
operations.

### Advisory Guidance

Ledger implementations SHOULD implement transaction deduplication for
`icrc2_approve` and `icrc2_transfer_from` according to the following rules:

#### Transaction Identity

- A transaction is identified by its transaction identity, which is the combination of:
  - the caller;
  - the method name (`icrc2_approve` or `icrc2_transfer_from`); and
  - the full set of method arguments, including `created_at_time` and `memo`
    if provided.

- Two calls with identical transaction identity are considered duplicates.

#### Time Window

- If `created_at_time` is provided:
  - The ledger SHOULD reject calls whose `created_at_time` is too far in the
    past or too far in the future relative to the ledger’s current time,
    returning a `TooOld`/`CreatedInFuture` error.
  - The ledger SHOULD define and document the accepted time window.
  - The ledger SHOULD NOT process duplicates.

- If `created_at_time` is not provided:
  - The ledger MAY process duplicates, or
  - MAY apply ledger-specific policies; such behavior SHOULD be documented.

#### Duplicate Handling

- If duplicate transactions are not processed:
  - The ledger SHOULD reject the call and return a `Duplicate` error.
  - The ledger MUST NOT apply the transaction effects again.

#### State Changes and Ordering

- Deduplication checks SHOULD be performed before any externally observable
  ledger effects are applied.
- `Duplicate`, `TooOld` or `CreatedInFuture` responses SHOULD imply that no balances, allowances,
  or transaction log entries have been modified.

#### Interaction with `expected_allowance`

- For `icrc2_approve`, the `expected_allowance` field provides an additional
  conditional update mechanism.
- `expected_allowance` does not replace transaction deduplication and SHOULD
  be evaluated only after deduplication checks have passed.

### Client Considerations

- When the ledger does not process duplicate transactions,
  **retrying an ICRC-2 call with identical parameters is safe** and will not
  result in duplicated ledger effects.
- Clients MAY rely on this behavior to safely retry requests in the presence
  of timeouts, transient failures, or uncertain outcomes.
- Clients SHOULD still be prepared to handle `Duplicate`/`TooOld`/`CreatedInFuture` errors
  and SHOULD avoid modifying parameters when retrying unless a new
  transaction is intended.

## 2. Error Semantics and Atomicity

### Clarification

The ICRC-2 specification does not explicitly state that `icrc2_approve` and
`icrc2_transfer_from` are atomic operations, nor does it clearly define which ledger
effects are guaranteed not to occur when an error is returned.

With the exception of `AllowanceChanged`, which explicitly states that no
allowance update has occurred, the semantics of other error variants are not
specified.

### Advisory Guidance

To align with common ledger expectations and reduce ambiguity:

- Ledger implementations SHOULD ensure that `icrc2_approve` and `icrc2_transfer_from`
  operations are atomic with respect to **externally observable ledger
  effects**, including:
  - account balances;
  - allowances; and
  - the transaction log.

- If an ICRC-2 method successfully applies such effects, the ledger SHOULD
  return a success response (`Ok(nat)`).

- If an error response is returned, the ledger SHOULD ensure that no externally
  observable ledger effects have occurred.

This guidance does not restrict ledgers from mutating internal or auxiliary
state (e.g., caches, metrics, rate limits, or bookkeeping data) when handling
a call that results in an error.

Additionally:

- Ledger implementations SHOULD document the meaning of each error variant.
- Client implementations SHOULD NOT assume stronger guarantees than those
  described above unless explicitly documented by the ledger.

## 3. Fees for `icrc2_approve` and `icrc2_transfer_from`

### Clarification

The ICRC-2 specification does not explicitly state the fees charged for
`icrc2_approve` or `icrc2_transfer_from`.

This advisory clarifies that these operations are expected to be charged
the same fee returned by the `icrc1_fee` method.

### Advisory Guidance

- Ledger implementations SHOULD charge the fee returned by `icrc1_fee` for
  both `icrc2_approve` and `icrc2_transfer_from`.
- Clients MAY assume that the applicable fee for ICRC-2 operations is the
  value returned by `icrc1_fee`.
- Fees SHOULD only be charged when the operation succeeds.
- The fee SHOULD be applied in a manner consistent with ICRC-1 transfers.

## Summary

ICRC-2 ledgers are expected to support transaction deduplication for
`icrc2_approve` and `icrc2_transfer_from` when `created_at_time` is provided,
to ensure that retries with identical parameters do not result in duplicated
externally observable ledger effects.

`icrc2_approve` and `icrc2_transfer_from` are expected to be atomic with
respect to externally observable ledger effects (balances, allowances, and the
transaction log). Error responses should imply that no externally observable
ledger effects have occurred.

ICRC-2 operations are expected to be charged the same fee returned by
`icrc1_fee`, and fees should only be charged when the operation succeeds.

