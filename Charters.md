# Ledger & Tokenization Working Group Charters

## 2022-12-06
[Slide deck](https://docs.google.com/presentation/d/1nHgxpfDhkfR1eou91wLRn8Zz634BfwccCkysqEvEOfM/edit?usp=share_link), [recording](https://drive.google.com/file/d/1qv6_OV472OwMiIYuzTW1d4jXFGU9N9Ia/view?usp=share_link)

**ICRC-2**

* ICRC-2 presentation
* Discussion
  * Overflow semantics (should we cap or fail in case of an overflow caused by an approval?)
    * The reason why we cannot allow for unbounded approvals is that this would result in unbounded numbers, which would be an attack vector against a ledger implementation  by exhausting their memory. Thus, balances and approvals are implemented as bounded number types.
    * A common case may be that a user has a limited approval already defined and makes another one with the maximum amount in the context of working with a DEX. The intention here is clearly to increase the approval to the maximum possible, thus having this succeed and cap at the maximum is the intended semantics.
    * For usability reasons: Cap, OK: nat
  * Question: transaction history -> ICRC-3 is defining this for the fungible token standard.
  * Question: atomicity -> The application should be able to handle it with the current definition of the ICRC-1 token standard.
  * Security model: allow user to opt out of approvals?
    * Limit user privileges? -> higher level issue
    * Would a revoke_all method be sufficient?
    * Separate issue to solve for all extensions
    * This seems to be a more fundamental UX issue
    * This should be documented in some form so people are aware of it
* Virtual humming: Rough consensus for ICRC-2 reached
* Next step is to initiate the voting, but only once we have made some adjustments to the working group and its governance structure.

**Working Group Governance (ICRC-0)**

* Arthur Falls presents his feedback from the side of the governance WG on ICRC-0
  * Most of his points are not on the substance of the proposal, but rather on being more open towardws different tools, not only focusing on GitHub
    * The process should be tool agnostic, it should only make recommendations on tools, but not prescribe tools
    * We need boilerplate to make sure that when people using different tools, it works together
  * Biggest problem with governance on the IC: not enough effectively-structured information in proposals for neurons to make effective decisions; not assertive enough community engagement for bringing proposals to the neurons; WGs should improve on this when making proposals to the NNS
  * Hosted two Twitter spaces to get community feedback on their WG results, was really useful
    * Concerns and opinions had developed responses to their concerns already
    * Do not rediscuss those in the future thanks to the documentation
  * Arthur presented the documentation system they used in the governance WG resulting in 4 documents
    * Originating Document: all ideas, framing the scope to work on, forum posts seemed relevant
    * Problems & Solutions Identification: 300 words; problem statement, solution; provides also external evidence to support their work
    * NNS Principles: Document that contains all their thinking, all ideas etc.; much more in depth; effectively structured; FAQ
    * Overview: pre-proposal; document with the wording they thought should be used in the proposal
  * The essence of why this process has been used is that people need to be able to see the thought process; that's why something like this is necessary
  * Arthur thinks that all objections and related discussions need to be documented in a referenceable form; PDFs are great for this as they don't change; having objections and the related discussions available will preempt discussions in the community in the future (all objections will come up again in the community and the available material can preempt it instead of us having to re-discuss the same things repeatedly whenever they come up in the community later)
    * All objections need to be recorded
    * Want to be really comprehensive about this to preempt similar community discussions
    * An FAQ might be useful for this
  * Using this approach, they had really nice community feedback
    * All the initial scepticism and controversy was removed through this transparent process
  * To summarize, Arthur likes the process we have described in ICRC-0
    * It needs to be more neutral in terms of the concrete tools
  * Discussion outcome
    * We want to have more details in the meeting minutes / charters
    * No agreement on whether static documents like PDFs or GitHub is more appropriate; either could be used, depending on preference on the working group or editors
      * Ben objected to mandate PDFs, because GitHub may be more suitable for many things and PDFs are not always the easiest to reference
    * The assertion that we should document objections and related discussions thoroughly finds support in the group
    * Being more open in terms of tools seems to make sense, e.g., leave the concrete choice of tools to the working group or editors
    * Roman proposes that a standard itself can contain the "why" we do not do certain things and thereby capture (parts of) objections in the standard itself
      * This makes lots of sense, but we might not want mandate it, rather it should be used as fits the standard at hand; in the end, the objections need to be captured somewhere

## 2022-11-01
[Slide deck](https://docs.google.com/presentation/d/1cgjTFmb72W9yrE8bkMq9JJSvDbEuzVuoj-R6xCiClOE/edit?usp=sharing)

Highlights:
  * The WG continued discussing the governance model.
    - The WG decided on using GitHub +1 / -1 over OpenChat for voting.
      Arguments: fewer tools to maintain, easier to find the voting pages, less anonymity.
  * ICRC-2 proposal:
    - The WG did not have objections to the allowance expiration proposal by Ben.
      The expiration should apply to the entire allowance to simplify the implementation.
      @roman-kashitsyn will update the spec to include expiration times.
    - The WG discussed the recipient filter proposed in https://github.com/dfinity/ICRC-1/issues/68.
      Everyone agreed that this extension is not helpful for most use cases and does not worth the trouble.
      We should submit a separate specification to address OpenChat use case (maybe bidirectional payment requests suggested by Timo).
  * ICRC-3 proposal:
    - There are no new technical details to dicsuss.
      Everyone is encouraged to read and comment on the spec: https://github.com/dfinity/ICRC-1/pull/66.
  * NFT standard:
    Ben will drive a separate WG that shall work on an NFT standard (ICRC-X).
    Austin expressed a desire to participate.
    Ben will start a thread on the forum to find interested parties.
  * Austin wanted to catch up with the recent WG meetings.
    @MarioDfinity to post links to the WG meeting recordings.
  * Next steps:
    - Vote on the textual representation.
      @roman-kashitsyn to create a GitHub issue for voting.
    - Implement ICRC-1 in the ICP ledger to demonstrate progress.

## 2022-10-18
[Slide deck](https://docs.google.com/presentation/d/1EFsM2aSpUecoLVTaCdFdjznN7X4CiDvwx8fq1tAp-GM/edit?usp=sharing)

Highlights:
  * We are continuing the discussion on the governance model for the WG.
    - Dieter described the two-step model where WG members decide using rough consensus and then submit an NNS proposal to make the standard "official."
    - Ben proposed an extension to Dieter's two-step model: the WG should post a proposal draft on the forum and let everyone provide feedback.
      Everyone liked the idea.
    - Dieter proposed to use Zoom's reactions feature (yes/no, not thumbs ups) to imitate the "humming."
    - Most people agreed that asynchronous collaboration on GitHub would be more inclusive and allow members from China to be more involved.
    - @roman-kashitsyn suggested having a "core team" or "official committee members."
      Those will be official members who will follow the WG process and apply the rough consensus model, accepting criticism from all interested parties (not only the WG members).
      We will reflect on the responsibilities of the "core members," and then Dieter will post on the forum to ask who wants to self-select.
  * There was a brief discussion of the ICRC-2 proposal:
    - @roman-kashitsyn is working on reference implementation [#65](https://github.com/dfinity/ICRC-1/pull/65).
      This work led to two observations:
      1. We should allow the ledger to reject `icrc2_approve` calls that result in huge (thousands of digits) allowances.
      2. It is unclear how the ledger should behave when the account owner calls `icrc2_transfer_from`.
         @roman-kashitsyn proposed that `icrc2_transfer_from` acts like a regular transfer in such cases.
         There were no objections from the audience.
    - Ben had two suggestions:
      1. Allowances should be compound (see [#65](https://github.com/dfinity/ICRC-1/pull/65)).
      2. Allowances should expire over time.
  * In the last few minutes, we looked at the [ICRC-3 proposal](https://github.com/dfinity/ICRC-1/pull/66).
    No feedback yet.

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
