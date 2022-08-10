# Ledger & Tokenization Working Group Charters

## 2022-08-09

[Slide deck](https://docs.google.com/presentation/d/1B4bplkQkFs5e32xnJl4Qr5xe5YhoSYJzsQuQ6BpaTfo/edit?usp=sharing)

Outline:
  * Overview of the Candid interface draft.
  * Overview of the form for the second internal vote on the standard draft.
  * Overview of the NNS proposal draft (see https://github.com/dfinity/ICRC-1/pull/44).
  * Retrospective on the WG process
    - What went well:
      * Back-and-forth interaction and exchange of ideas
      * Good result
      * Community involvement
      * Frequency is good
    - What could we improve
      * Synchronization between the WG and the forum
      * Very hard to comprehend everything that happens.
      * The goals weren't very clear
      * The way we make decisions wasn't clear
    - Action items
      * Keep discussions in GH in the form of issues and PRs and make regular updates on the forum.
      * Continue the charters log.
      * Make the goals clearer before starting the next spec.
      * Refine a process for making decisions:
        1. Create a proposal PR.
        2. Bring up the proposal in the WG and give 1 week for contemplation.
        3. Discuss in the next WG and then merge/close
        4. Record the decision in the Charters.

Next steps:
  1. Vote on the draft using the internal WG form until 2022-08-10 19:00 CET.
  2. Comment the NNS proposal draft (see https://github.com/dfinity/ICRC-1/pull/44) that will be submitted on 2022-08-10 if the majority in the WG votes for the standard draft.

## 2022-08-02

[Slide deck](https://docs.google.com/presentation/d/1YptXrmtPEHYcQpnZwMC05zgNYbBVuV4ZZKejEc0wOWg/edit?usp=sharing)

Decisions made:

  * Follow up on #32: rename `Account.principal` → `Account.owner` (implemented in https://github.com/dfinity/ICRC-1/pull/41).

    Rationale: "principal" is a reserved identifier in Candid, using this identified can create unnecessary complication when calling the ledger from the command line.

  * `icrc1_minting_account` (proposed in https://github.com/dfinity/ICRC-1/pull/29): make the result optional: `icrc1_minting_account : () -> (opt Account) query`.

    Add related metadata entries when we have a text representation for `Account`.

  * Structural deduplication (proposed in https://github.com/dfinity/ICRC-1/pull/24): accepted.

  * `icrc1_fee` (suggested in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/33): accepted

  * Larger memos (suggested in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/38): accepted

  * TransferError type (questioned in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/43):

    - Add another variant like `Overloaded` or `Throttled` to cover a recoverable error indicating that the ledger is overloaded.

    - Remove the window from `TooOld`.

    - Add the current ledger time to `CreatedInFuture` variant.
