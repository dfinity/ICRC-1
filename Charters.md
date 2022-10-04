# Ledger & Tokenization Working Group Charters

## 2022-10-04
[Slide deck](https://docs.google.com/presentation/d/1_xiYE4Ng8gz_u_dNos-xxZ1Ro6ckOwBMkm0fBgMaYLI/edit#slide=id.g125c3b1bfa8_0_0)

Highlights:
  * Dieter presented a proposal for the governance model for the Working group.
    One idea was to adopt the rough consensus model like IETF, see [RFC 7282](https://www.rfc-editor.org/rfc/rfc7282).
    The WG agreed that rough consensus seems to be a good fit.
    Questions raised:
    - Should we create NNS votes for decisions affecting the community?
    - How do we decide who constitutes the WG?
      If we do not know the exact members, it is hard to be sure that we take everybody's opinion into account.
    - Often there are no objections in the WG discussions, but when you ask people to vote and explain their decision, there is a lot of valuable feedback.
      How do we address that?
  * The WG discussed the ICRC-2 proposal by Psychedelic: https://github.com/dfinity/ICRC-1/tree/f8c39bec71b1ac7f6cdb1a6c9844726efc58be38/standards/ICRC-2.
  * The main concern about ICRC-20 is that ERC-20–style approve/transfer_from does not work well with concurrency:
    If A approves five tokens to B, then A notifies B, then A approves ten tokens to B, then A notifiers B, the following message sequence is possible:
    - The Ledger sees five-token approval and accepts it.
    - The Ledger sees a ten-token approval and accepts it.
    - B tries to transfer five tokens and succeeds.
      The Ledger reduces the allowance to five tokens.
    - B tries to transfer ten tokens and fails.
  * The WG agreed that making approvals additive, as suggested in https://github.com/dfinity/ICRC-1/issues/22, seems to be the best option.
    @roman-kashitsyn will make a PR with that adjustment.
  * Max proposed that we get back to the transaction log extension.
    @roman-kashitsyn will make a PR with the ICRC-3 proposal for the transaction log API.

## 2022-09-20
- [Slide deck (Dieter)](https://docs.google.com/presentation/d/1r85i2iAkli6dv-Ou_rD6l3wA2RTHoggBBsxXaj3rvFo/edit#slide=id.g125c3b1bfa8_0_0)
- [Slide deck (Ossian)](https://docs.google.com/presentation/d/1ic4iwKEmvbTFcc5j4LkoVhqx9O1iodw3w9QoQXEQTU8/edit#slide=id.gc6fa3c898_0_0)

Highlights:
  * Textual encoding spec got an update [#55](https://github.com/dfinity/ICRC-1/pull/55).
    The latest encoding version is unique (each valid encoding corresponds to a unique account), which is an essential property for block explorers and dashboards.
  * Timo Hanke proposes a generalization of the ICRC-1 textual encoding: https://forum.dfinity.org/t/using-the-principals-textual-encoding-for-other-things-than-principals/15319
  * Ossian proposed the ICRC-2 extension for the approve/transfer_from flow.
    No objections from the WG, but we need to sort out the exact API.
    Ossian will create a PR with the extension, @roman-kashitsyn will help with the details.
  * Discussed where the extensions should live.
    Agreed that we can start adding extensions to the https://github.com/dfinity/ICRC-1 repo, we can revise this decision later.
## 2022-09-06

[Slide deck](https://docs.google.com/presentation/d/1Z_QwRkRxDFO1iZl11QzMtBTm82MfkrPgfkUc9PX7Nj8/edit#slide=id.g125c3b1bfa8_0_0)

Highlights:

  * Textual encoding spec is up for review: [#55](https://github.com/dfinity/ICRC-1/pull/55)
    No objections in the working group, likely to be stabilized by the next meeting.

  * We now have basic acceptance tests: https://github.com/dfinity/ICRC-1/tree/0b57f3a85f20b178767192968867c4addeb076f2/test.
    @roman-kashitsyn will work on adding more tests.

  * The working group meetings will be biweekly, the next session is on September 20th.
    Larger breaks allow us to do more work in the meantime and gain more experience and data.
    Dieter Sommer will take over the working group initiative.

  * The next time, we'll get speakers from [Psychedelic](https://github.com/Psychedelic) presenting approve/transferFrom extensions and subaccount management ideas.

## 2022-08-23

[Slide deck](https://docs.google.com/presentation/d/1wZMylD6PbzhrLwhr72--Fxfm9jjSSTw-Rys8TSGp76o/edit?usp=sharing)

Decisions made:
  * The principal encoding seems to be the most promising format for representing composite accounts.
    @roman-kashitsyn will make a post with the WG proposal to measure the community reaction.
    If there are no strong arguments against this decision, we can finalize it next week and update the standard text.

  * The WG shall start working on the transaction log extension.

  * The are no objections to splitting the API for fetching the transaction log into multiple parts:
    - The Candid API without certification capabilities (for Canisters and UI).
    - An optimized batch API with verifiable encoding and certification capabilities (for Rosetta nodes and similar batch tools).

  * No objections to using records + kind to represent extensible variants in Candid.

  * There are two options for the API to fetch transactions in the presence of archives:
    we can either assemble transactions from archives on the Ledger side (as in DIP20) or introduce the fetch protocol that exposes archives (as in the ICP ledger).

    Arguments for assembling transactions on the Ledger:
    - The API is much simpler.
    - If the Ledger and the Archive are on the same subnet, the communication overhead is probably negligible.
    - Archives can be "private", allowing only the ledger to talk to them.

    Arguments for using query calls for fetching transactions:
    - Queries are significantly faster when called outside of the IC, allowing apps like wallets to provide a better UX.
    - The ledger becomes less of a bottleneck when the client needs to fetch a lot of transactions:
      the first call will have to go to the ledger, but all subsequent calls can go directly to the archive.

  * The transaction log feature will not include indexing by user/account:
    - We could implement indexing in a separate canister using the simple transaction fetch API.
    - This feature will require spreading the index across multiple canisters (the ledger and the archives), complicating the implementation on the ledger side significantly.

  * For now, extensions will live in the ICRC-1 repository in a separate directory.

## 2022-08-16

[Slide deck](https://docs.google.com/presentation/d/1sggeGP-RsLADfgHdIp6BYqsfGkmD1QRtBkPtLUadxwk/edit?usp=sharing)

Decisions made:
  * We need to compile the list of helpful extensions, understand which issues they solve, and work on the most useful first.
    Current candidates are:
    - Transaction log access & certification.
    - Pre-signed transactions.
    - Transfer-notify flow.
    - Approve/transferFrom flow.
  * Textual encoding:
    No clear winner, but using the principal encoding format is the most promising.
    @roman-kashitsyn to compile a table with main options and their weaknesses/strengths.
    We will gauge interest on the forum and have a WG vote later.

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
      * Refine the process for making decisions:
        1. Create a proposal PR.
        2. Bring up the proposal in the WG and give 1 week for contemplation.
        3. Discuss in the next WG and then merge/close
        4. Record the decision in the Charters.

Next steps:
  1. Vote on the draft using the internal WG form until 2022-08-10 19:00 CET.
  2. Comment on the NNS proposal draft (see https://github.com/dfinity/ICRC-1/pull/44) that will be submitted on 2022-08-10 if the majority in the WG votes for the standard draft.

## 2022-08-02

[Slide deck](https://docs.google.com/presentation/d/1YptXrmtPEHYcQpnZwMC05zgNYbBVuV4ZZKejEc0wOWg/edit?usp=sharing)

Decisions made:

  * Follow up on #32: rename `Account.principal` → `Account.owner` (implemented in https://github.com/dfinity/ICRC-1/pull/41).

    Rationale: "principal" is a reserved identifier in Candid, using this identifier can create unnecessary complications when calling the ledger from the command line.

  * `icrc1_minting_account` (proposed in https://github.com/dfinity/ICRC-1/pull/29): make the result optional: `icrc1_minting_account : () -> (opt Account) query`.

    Add related metadata entries when we have a text representation for `Account`.

  * Structural deduplication (proposed in https://github.com/dfinity/ICRC-1/pull/24): accepted.

  * `icrc1_fee` (suggested in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/33): accepted

  * Larger memos (suggested in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/38): accepted

  * TransferError type (questioned in https://github.com/dfinity/ICRC-1/issues/30, proposed in https://github.com/dfinity/ICRC-1/pull/43):

    - Add another variant like `Overloaded` or `Throttled` to cover a recoverable error indicating that the ledger is overloaded.

    - Remove the window from `TooOld`.

    - Add the current ledger time to the `CreatedInFuture` variant.
