# Ledger & Tokenization Working Group Charters


## 2023-01-10
[Slide deck](https://docs.google.com/presentation/d/1bADDPijUR653DfoS3cZ5HLJuRLXSMeXZcQjZGCz_U0o/edit), [recording](https://drive.google.com/file/d/1D-XGvc69IbH5J4UZwGxO5agMIoTzHYex/view)

**ICRC-2: Next steps**

* Dieter suggests the following next steps
  * Presenting ICRC-2 in an upcoming Global R&D (Roman)
  * Submitting an NNS proposal for making ICRC-2 an ICP standard
* Levi points out that Austin made a post on the forum on how he made an ICRC-2 canister to escrow approvals just using the ICRC-1 standard; essentially, it adds ICRC-2 to ICRC-1 canister; Do we still require ICRC-2 then?
  * We need ICRC-2 if want it atomically, inside canister
  * Austin's canister: If ledger canister does not have ICRC-2, that canister would give you ICRC-2 workflow and interface; but not atomically; different model than having ICRC-2 directly in the token ledger, which is more powerful
  * Austin clarifies that this does not obsolete ICRC-2; having ICRC-2 interfaces on a ledger is super important; will be using it at Origyn
* There is agreement in the group that we move forward as proposed

**ICRC-3: A standard for accessing the transaction log**

* Dieter explains the current ICRC-3 proposal
  * ICRC-3 allows canister to access the transaction log of a ledger
  * Scalability, archive canisters, scather-gather-type interface
  * Support for the upcoming NFT standard as well
  * ... see slides for details

* Philipp Litzenberger raises a question: Are queries supported, such as getting the transactions for a specific account?
  * This is not part of the standard
  * The standard is only to get the transaction log
  * Querying is a functionality of the index canister that indexes transactions by account and principal
  * The index canister is a companion canister to the ledger

* Matthew Harmon raises a question about integrity of data: Is it possible that the integrity of data is protected so the client can give data to another party who can verify the data?
  * Roman responds that this is not possible
  * Certified variables work for outside of the IC, but not for canisters
  * There is no good solution to this problem, any solution would be hard to implement
    * No access to signatures of the subnet in the replicated context; certified variables: no access to them inside the IC; would be technically very hard to implement
  * Outside of IC, certified variables is just an optimization that allows for using a query instead of update call
  * There are two levels for representing transactions
    * Transactions: Transactions come from the client
    * Blocks: Wraps transaction from client into envelope; contains pointer to previous block and timestamp; is like a block in a blockchain containing one transaction; can be verified
  * But the ICRC-3 interface is meant for canisters to access, does not provide any proof; if you would like to compute hashes to verify stuff, it is painful with this interface
  * Other thing you can do is make update call and get transaction object, update call contains signature, so need no other proofs, but is substantially more expensive
  * ICRC-3 is for canisters, they don't care about proofs, care about transaction data
  * For Rosetta nodes, which need to verify blockchains, we will probably have a different API
  * To summarize, there is no way to achieve to have a proof that can be give to other parties for the query response on the IC for a canister client

* Roman clarifies why the GetTransactionsResponse contains the log_length parameter
  * Mental model: Some transactions are still in the ledger; ledger batches transactions before sending them downstream; other transactions are in the archives; when we query the ledger for transactions, if it has them locally, it can return them right away; for transactions in archives, it returns a pointer to the archive; the client will know what the latest transaction for the ledger is

* Plan for standardizing
  * Collect further input from all people in the WG and wider community
    * Post it in forum
    * Bring it up in upcoming meetings
  * Refine draft
  * Have a WG vote on it

* Roman notes that if ICRC-2 comes out before ICRC-3, **we should include new transaction types so that ICRC-3 covers approve and transfer_from transactions already**

* **Roman suggests to change modeling of transaction types**
  * Now we use a huge record with plenty of optional fields
    * Because Candid did not support extensible variants
  * Should use extensible variantes: transaction ... opt variant with types
  * New Candid release with support for this is coming today or tomorrow
    * Extensible variants
      * If have option with variant, tries to decode
      * Even if types fo not match
        * If success, it uses the value
        * Otherwise, sets it to null
  * Mario
    * Variants are much easier to use then records in his experience
    * Strongly advocates using variants
  * **Decision to use variant instead of the record, everyone agrees**
    * Cleaner
    * Easier to use in code

* Philipp expresses a strong feeling that we need a filter option when reading data from a ledger's archives
  * Otherwise, we need to retrieve all data of all archives and filter at client
  * Filter is used to specify what kind of transactions we want to have
  * Opportunity to pass more filter options per transaction type
    * Want to receive mint transaction for specific account
    * Or transfer transaction for specific account
  * Otherwise need client-side filtering, but too much data for this
    * Or build index canister
  * Roman mentions that the problem is that the ledger cannot filter as it does not have the transactions and does not have an index; only has balances and pointer to archive
  * Philipp: We could do same filtering on ledger and every archive canister to get a filtered response
    * Use is most likely within wallets to display transactions to the users
    * Mostly clients would want user-specific transactions
  * Mario: If want to have this on the archive, need to add an index
    * Every wallet would ask archives all the time and create heavy load and cycle consuming
    * Want to have caching of information somewhere, e.g., for Wallets
    * Reason for index canister
      * Index canister fetches transactions from ledger and archives once
      * Index canister could offer data in fast way compared to ledger and archive
      * Index could comprise a set of canisters for very large transaction sets
    * Have the following options to realize an index
      * Keep only subset of transactions, e.g., last 1000 per user
      * Keep full list of transactions
      * Keep pointers to transactions (done for NNS currently); when frontend asks for transactions, index canister fetches them from ledger or archives; index needs to be on the same subnet as ledger for this to be performant
  * Index canister that does not hold transactions and pulls transactions from archives is slow if not on same subnet

* We may want to standardize also the API of the index canister to be useful
  * Separate API for index canisters as accessed from clients

* Roman: Don't know in advance what you want to index
  * With arbitrary query, would need database in every index that can efficiently answer all queries; all within the cycles limit and with multiple canisters
  * Goal of ICRC-3 was to have a means to obtain the transaction data
  * Can build index canister that syncs transactions you want, builds index you want, and serve queries to clients

* **Need a forum discussion how a wallet interacts with the ledgers**
  * ICRC-3 is not enough for wallet developers, need something more
  * This WG could work on index or multi-canister solution
  * Currently, most of wallets are building their own index canister

* Could work on an interface for the index canister
  * Maybe make it discoverable via the ledger
    * Client can ask ledger whether it has an index and ledger can point to it
  * Index canister must comply with index API, can be queries according to API

* 2 architecture options for index canisters
  * Make every archive into an index
    * Each archive becomes complicated; now 1 page of code
    * Ledger includes archive in its own memory, cannot have large codebase here
    * Nice that archive is small, stupid thing that dumps blocks into stable memory and serves them
    * Don't want archive to be complex, want it simple; don't want bugs there
  * Have separate index canister in addition to archive

* Index should not necessarily be a single-canister solution
  * Index may be huge for large set of transactions
  * Many ways to implement different designs for this; have all options you want
    * Index canister can delegate queries to smart archives or index helper canisters
      * Index canister is coordinator that uses further canisters; finds data for you
      * Coordinate distributed queries
      * Ledger points to coordinator for index discovery
      * Clients use coordinator as index canister
    * Everything in one big canister that keeps everything
      * Ledger points to itself for index discovery
      * Ledger implements index itself and serves index queries

* Conclusion
  * *ICRC-3 still needed as a foundation for all index canister functionality*
  * *Current functionality of ICRC-3 seems sufficient for the foundation*

## 2022-12-13
[Slide deck](https://docs.google.com/presentation/d/1dxypgWRN5Vz30uy2mdMIDqNBoNbMKMRibw5DU34xiMs/edit#slide=id.g125c3b1bfa8_0_0), recording not available

**Communication & collaboration channels**

* Dieter summarizes the communications and collaboration channels used by the WG
Working group composition
* We agree to adapt the composition of the core WG to reality of participation
  * Ossian Mapes (the same person as Oz Waldorf) leaves the group as Fleek has left the IC ecosystem for now
  * The new core team now is composed of the following people:
    * Alessandro Rietmann
    * Max Chamberlin
    * Austin Fatheree
    * Levi Feldman
    * Jordan Last
    * Daniel Steren
    * Matthew Harmon
    * Jorgen Hookham
    * Roman Kashitsyn
    * Mario Pastorelli
    * Ben Zhai
    * Dieter Sommer
    * Vesselin Tsukev (requested to join; membership conditioned on participation)
    * Witter Lee (located in Asia, cannot attend regular meeting; membership conditioned on participation)
  * We need to see whether participation works out for Vesselin and Witter (asynchronous only) and depending on this, they can remain part of the group or leave it
  * The new WG composition was accepted by a hum, without objections

**Working group composition – WG co-leads**

* Volunteering as WG co-leads
  * Dieter Sommer
  * Ben Zhai
  * Tim Hermann
* On request to the group, no one from the community would join as another volunteer for now. Anyone interested in volunteering for this role in the future can approach us.
* The above co-chairs were accepted by a hum without objections.

**Proposed change to voting**

* The proposed change to not require a 50% minimum quorum of participants for a vote to be valid was accepted by a hum without objections.

**Governance**

* Dieter recaps the main points brought into the group by Arthur Falls in the previous working group meeting.
  * Communication of the proposal and objections, the importance of presenting proposals to the wider community.
  * Keeping clear record of the discussions and objections.
  * He emphasizes that the WG must not bias the decisions of the neurons by a summary, which may eventually be biased.
* Matt emphasizes the point that crypto people don't want to read specs, they will rather watch a video, but otherwise agrees
* The group agrees that we should use videos to present our results
* The group agrees that this is an important point and we should strive to do a video presentation for at least the larger and important outputs
  * It was suggested to use the Global R&D as a platform for presenting important results
* After some discussion about how democracy on the IC works, Arthur agrees on the pragmatic approach proposed in ICRC-0 and that good communication of proposals with presentations is the key to disseminate the ideas and get feedback from the community.

**Textual encoding format for ICRC-1 account addresses**

* When we wanted to re-open the vote, Max brought up a suggestion on whether we want to have a more readable form of the representation, namely a separator between the principal and subaccount for better readability. We had a discsussion on this and whether this could retain the nice properties of the current scheme and could not come to a definite conclusion. We decided to bring this discussion back on the [forum](https://forum.dfinity.org/t/announcing-token-standard-as-topic-of-the-first-meeting-of-the-ledger-tokenization-working-group/11925) and make an attempt to resolve it there within the coming days. Max will start the discussion by bringing up his argument.

**ICRC-2 proposal**

* The [vote](https://github.com/dfinity/ICRC-1/issues/77) for [ICRC-2](https://github.com/dfinity/ICRC-1/blob/main/standards/ICRC-2/README.md) is open now. Voting period is one week from when it was opened.
* [YouTube explainer](https://www.youtube.com/watch?v=IYTglSXtUtg)

**Next meeting**

* January 10, 2023
* The December 27 meeting is dropped due to holiday season


## 2022-12-06
[Slide deck](https://docs.google.com/presentation/d/1nHgxpfDhkfR1eou91wLRn8Zz634BfwccCkysqEvEOfM/edit?usp=share_link), [ICRC-2 slides](https://docs.google.com/presentation/d/1ltqc1GR2BXcbVSU1KrW4h3LTXa7ZWudnaOdMmBjini4/edit#slide=id.p), [documents](https://docs.google.com/document/d/1OlP7fwplFiKQlWuDNgdes0iWd61q230VHlyBrKJkYbs/edit), [recording](https://drive.google.com/file/d/1qv6_OV472OwMiIYuzTW1d4jXFGU9N9Ia/view?usp=share_link)

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
  * [Presented documents](https://docs.google.com/document/d/1OlP7fwplFiKQlWuDNgdes0iWd61q230VHlyBrKJkYbs/edit)
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

## 2022-11-15
[Slide deck](https://docs.google.com/presentation/d/10PxWKYbWdZUmnafIMrc6_bdvNBwBCXHiHQnoRR8kIT0/edit#slide=id.g15a049007c6_0_20)

Highlights:
  * The ICRC-2 proposal seems to be feature-complete.
    @roman-kashitsyn and @ozwaldorf will prepare slides with the overall design overview and present them in one of the following community conversations.
  * The ICRC-0 proposal on governance by @dietersommer is open for review (https://github.com/dfinity/ICRC-1/pull/71).
    @dietersommer will sync with the governance working group and get feedback.
  * There is a new repository for community-driven proposals: https://github.com/dfinity/ICRC.
    The processes for creating new proposals and allocating standard IDs are TBD.
  * The WG had a conversation on whether we need many token-related ICRC-x proposals or whether there should be a single standard that newcomers can easily understand and adopt.
    The plan is to proceed as we planned before:
    - Keep working on the most needed missing pieces (approvals, transaction log, certification, presigned transactions).
    - Once we have a solid base, we can group them under an umbrella "core" standard that most new ledgers could use.

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
