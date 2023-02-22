# Ledger & Tokenization Working Group Charters

## 2023-02-21
[Slide deck](https://docs.google.com/presentation/d/1c62oP0p3bM2B21n5ORYI0OAJWVEytO0vCjEspTnIIgw/edit#slide=id.g20f9d73110e_0_20), [recording](https://drive.google.com/file/d/1lHevLT_Dmk-2wpyJ4chhzsJE00SYtiR3/view?usp=share_link)

**Encoding of accounts**

* **Encoding of account, main decision**
* Dieter summarizes where we stand regarding the encoding discussion
  * Latest thinking is that principal + "-" + checksum + "." + subaccount is a good compromise given that the standalong principal is used a lot already these days
    * Principal can still be compared by eye with possibly a little confusion
    * Risk of wrong copy/pasting up to end of the "perceived principal" is avoided
* Discussion starts
  * Matthew: likely there will be some confusion no matter what we do
  * Levi: there are principals and subaccounts shown on the dashboard already; principal must be able to be its own identifier, subaccount must be shown clearly
    * Hyphen-subaccount is nice
    * Levi is fine with the proposed approach
  * Roman agrees as well, approach looks good to him; it is important that when collating accounts, that accounts with the same principal are nearby; this approach achieves this
  * Alessandro: is fine with it
  * **The group agrees on the proposed solution**
    * Principal = default subaccount
    * Other subaccounts: The checksum is suffixed with "-"-separator to the principal, this is followed by "." and the subaccount
  * Roman volunteers for sketching a first draft of the specification
* **Trimming of leading zeroes**
  * **People agree with trimming leading zeroes at the character level**
* **Checksum algorithm and checksum length**
  * Current working assumption has been 4 characters
  * CRC32 seems fine, SHA is most secure one and is likely not required for this
  * CRC32 is used for the checksum in the principal
  * CRC32 is easy to implement
  * Is it safe to trim a CRC32 checksum to fewer bits?
  * Checksum will be fixed length, cannot have different length then, unless we have a new version of the standard
  * 32 bits would be 7 characters
  * **Roman agrees to look into using a CRC with fewer bits**

**A standard for DAB and replacing DAB**

* Ben presents the need for a replacement of DAB
  * DAB is token registry for both fungible and non-fungible tokens
    * If you have token called "ABC", anyone can issue such token
    * The ledger gives the name
    * Potential for phising attacks here
    * For this reason we need a registry for tokens; DAB is such registry
    * They manually approve tokens
  * DAB is not maintained
  * DAB is a centralized service
  * Don't want centralized token registry
  * Motivation and proposal
    * Record preferences on the wallet level; completely decentralized
    * If there are two tokens called "ABC", a user would usually know which token they are interacting with; they can add that token as their preference
    * Wallets and NFT marketplaces: in order to know which tokens a user owns, they don't need to query all existing ledgers to know which tokens user owns; this is what currently the NFT marketplaces do; not sustainable; Entrepot currently queries around 600 canisters when user logs in to know which NFTs they own
    * Benefit of registry on wallet level
      * Marketplaces will know which tokens user is interested in
      * Not possible in Ethereum as it is too expensive there to store such data
      * Each dapp keeps whitelist of their own
    * Proposal does not require central authority
    * Should be standardized as an ICRC standard
* Discussion
  * Roman
    * Financial Integrations team has been thinking about this for a long time
    * Would prefer central canister on the NNS subnet
    * People can submit proposals for adding their token canisters
    * NNS governance manages this in decentralized way
    * Avoid confusion of having different configurations in different wallets
    * Each token symbol could be registered once
  * Austin asks whether in Roman's approach every token would need to go through NNS vote
    * Would highly recommend not doing this; minefield; not there yet in terms of governance
    * Not pleasant user experience at all
    * Socially, community not ready yet
  * Ben
    * NNS should handle limited things, and not expand to application level too much
    * This would be application-level access control
    * Anti-pattern for NNS
  * Max
    * Understands this is a registry for users' tokens
  * Austin
    * Understands that it would be a mapping from principal to the NFTs user follows
    * Would want to give another service permission in which NFTs one is interested in
    * Any kind of centralized service for this gets tricky quickly
      * Who gets approved
      * What counts as spam
      * What if someone wants to blacklist someone else
  * Max
    * Integration challenge
  * Levi
    * Asks for clarification of proposals having been made
  * Roman: was talking about registry of unique symbols only
    * Central ledger with all token names
    * Need some trustworthy way to officially register tokens
    * Would prefer canister with well-known address holding index of all tokens
  * Max
    * Not as big an issue as for fungible tokens; no NFT naming issues
    * Since DAB left, there is no registry where we can find which users own which NFTs; seems completely separate issue to Roman's point
  * Levi agrees this is a different solution; would start with ledger symbol reservation canister as first step
  * Ben
    * Thinks there should be possibility of multiple tokens with the same name; which token gets accepted by community is a different question; on Ethereum you can have multiple tokens with the same name
    * Can be resolved on the wallet level on IC; not possible on Ethereum
    * Sees this as better solution to have central canister to register wallet-level preferences
  * Max
    * Should focus what problems are for the people, wallets, users
    * Token names is not a problem; can import this as a list
    * If user wants to add custom token, can do that by principal id or address
    * Main problem right now: discovering NFTs is hard
      * NFTs are not like fungible tokens where there are a few famous ones
      * Need to be able to discover NFTs if you want all of yours in one wallet
  * Roman
    * Agrees
    * Need different solutions to different problems
    * Central canister for fungible tokens would be great
    * NFTs is separate problem, NNS should definitely not handle this
  * Levi
    * What happens when user gets an NFT?
  * Max clarifies existing approaches for handling NFTs
    * DAB approach
      * Creators register their NFT with DAB and inform it about which standard it uses
      * You can use DAB to find out whether you own particular NFTs
    * Other approach
      * Pull information directly from the NFT marketplaces
      * Marketplace must provide endpoint that canister can query for this
      * No central party like DAB involved in that case
    * Closely-related question to what are the standards for NFTs
      * Once define standard for NFTs, it's trivial to make canister that can query all different NFTs that are out there; currently have several different standards
    * Connected question is what the NFT standard is
  * Ben thinks that this proposal would not be specific to NFTs
    * Ben disagrees with the assertion that fungile and non-fungible tokens should be handled differently; what about semi-fungible; they are all tokens and should be handled in the same way, there is no fundamental difference
  * We agree to continue the discussion on the forum and pick it up again next time  

**ICRC-2: Final recap before NNS vote**

* ICRC-2 brings over the idea of the approve/transferFrom flow from Ethereum
  * Do group members have any additional thoughts about the current standard before we take it to an NNS vote?
* Discussion
  * Roman: once approved by NNS vote, will implement ICRC-2 in all our ledgers
  * Levi: recurring payments is one of the goals for ICRC-2; e.g., subscriptions
    * What about adding an interval argument, e.g., to approve a given payment every 30 days
    * Now user needs to agree on larger sum for longer time period
  * Roman: would complicate ledger a lot; language to express installments may be pretty complicated; need to trust application anyway to some extend; if we do it, should be simple
  * Approval is always from a specific subaccount
  * Transfers behave as if you sent them yourself
  * Ben: very good use case scenario; but need to draw boundaries clearly; thinks, this should not go into the ledger
    * Can approve one subaccount to one application; can control risk exposure
    * Can have canister wallet that periodically increases approval
  * Levi: most people waiting for ICRC-2 are waiting for recurring payments
  * Ben: recurring payments can still be done; comparable to using a credit card for any subscription in the real world
    * Feedback he got is that people want improved payment flow
  * Levi will think about it and see whether he can come up with a simple API
    * See whether this would be worth the tradeoff
  * Roman: functionality might require to keep longer tx history, need to look into it in more detail to make conclusive assessment; might need to store lots of tx in memory
  * Continue discussion of this on the forum and upcoming meeting


## 2023-02-07
[Slide deck](https://docs.google.com/presentation/d/1vCIl8bMFcKUVyoNZl0MAq8WlSI_U2cBAPgN8XxO05BE/edit?usp=share_link), [recording](https://drive.google.com/file/d/1bgYyay1jgox2Cw6cm67lbEiKwDEAE0qx/view?usp=share_link)

* Dieter summarizes the progress of the last meeting where we have found the best options to consider
  * Options 4b and 4c remain
  * Both have a fixed-length checksum element and a human-readable representation
  * 4b: checksum in the middle
  * 4c: checksum at the end
  * Separator still t.b.d.
    * Different variants available based on separator used
* Discussion starts
* Milind would prefer 4c with checksum in the end as a natural continuation of principal and subaccount
  * People generally prefer the checksum at the end
* **Discussion on separator**
  * Ben: separators we use should not constrain application, e.g., encoding embedded in a QR code:
    * Should be compatible with URI scheme
      * Should not use colon as it would mean something in the URI scheme
  * Could use "." and "-"
  * Could use "+", as it is a valid character
  * Austin: What to prioritize?
    * Understanding
    * Practical simplicity (".")
  * Ben would opt for simplicity; could have just one "." separator
  * Dieter: one separator harms human readibility, need to count characters in subaccount/checksum to see where subaccount ends
  * If we treat subaccount and checksum as integral part, don't care what is the checksum
  * Ben: assumption: no use case where user needs to populate principal and subaccount separately
  * Working assumption: 4 hex characters (16 bits) of checksum, fixed-length checksum
  * Timo: Now thinks that in the use case of subaccount being large (e.g., Ethereum address), one would want to see the subaccount explicitly, which is hard with no separator; therefore, not use the "." / "" option
    * People agree
    * Dieter: cleaner to use another separator for checksum
  * Dieter proposes to narrow selection to "." / "--" (or single dash) and "." / "."
    * People agree
  * "--" is easier to parse as second separator, "." is more uniform
  * Both are similarly bad in double-click selection behaviour, no big difference
  * Timo: strong separation is not an argument any more; don't like the "-" because of confusion with principal part; undecided between "." and "--"
    * Using "." may make it look hiararchical, like a domain name, "--" does not have this
  * Max: very subjective at this point; likes ":" or "::"
    * Dieter: not a valid character as discussed earlier
  * We try how the "+" looks as second separator
    * Max likes it, "+" has meaning of check"sum"
    * Ben: would be OK for URI scheme, there is a slight remaining risk; tend to avoid it
    * Austin: in a URI, "+" is space, might be problem when copy/pasting
    * Dieter: technological risk; let's not use it
  * Max: What about caret or tilde? "^" or "~"
    * Ben: cannot use caret; tilde is valid; want to avoid non-common separators; on user side, may create confusion
    * Austin thinks "." is good
    * "=" sign: part of query string, would need to be encoded in URI
    * Austin: "-", ".", "_", "~" are OK according to URI scheme specification
    * "~" look out of the norm, "_" looks misplaced
  * Timo: is tradeoff
    * What about "--"?
    * Austin: is extra character
    * Single dash: only downside that it also has meaning in the principal
    * Ben prefers "-" over "." due to hierarchy implied by multiple "." in the encoding
  * Dieter proposes to settle for "-" as checksum separator
    * People agree
* **Handling of default account**
  * Dieter presents the options of Slide 8
    * Option 1: explicit default subaccount
    * Option 2: implied by using plain principal only
    * Option 3: principal with extra checksum
  * Austin: "--" prevented half-byte when parsing; half-byte makes parser somewhat more complicated, but "-" should be fine
  * Austin likes just having a principal for default subaccount
  * Dieter: argument against it is copy/paste error; just copy principal instead of the full encoding, and tokens go to default subaccount instead the intended subaccount
  * Max would still go for Option 2 for backward compatibility
    * Ben: going forward, there would be no place for inserting principal and subaccount separately in a user interface; we always use the encoding
    * Roman: if we don't support Option 2, people will support both mechanisms anyway, which creates optionality; people can just ignore encoding and make transfers between principals
    * Ben: if app decides to support interface to transfer to principal, but when sticking with textual encoding, it should be very explicit; input field has type textual encoding; standard should specify something explicit
  * Max: people are already supporting principals; if we change that, users will try to enter principals for default accounts; not sure how smooth the transition will be
  * Ben: there will be transition issues; during transition period, can implement this as an option, when mainstream adoption is here, hopefully everyone adapts explicit encoding
  * Discussion on copy/paste errors when using principal for default subaccount
    * Ben: what if user just knows the principal concept? recognizes principal and transfers to principal instead of full address
  * Roman: most would support both approaches anyway; people may prefer to send to principal directly; immediately useful; thinks Option 2 is the best choice
  * Austin: also thinks 2 is good as it is already out there
  * Discussion on whether this could be implemented as part of the frontend; principal transfer can still be supported; have branch in frontend to call either
  * Roman: browser extensions have little screen real estate, they may just shown one field; security argument gone then
  * If we have the option in the frontend, we don't really have uniquness
    * Timo: paste something in, later look at block explorer, you expect the same thing; don't like this translation happening in the back; what user pastes and sees should be the same data
    * Levi: allowing the principal itself is an issue because of copy/paste errors when missing subaccount
    * Timo: would accept that risk; if someone copies only the principal of the whole encoding, we can probably accept this
  * Ben: What about checksum in the middle, attached with "-" to principal? blends in checksum with principal
    * Properties
      * Less risk to just copy the principal and miss the checksum and subaccount
      * Little less readability of principal
      * Would be compromise between reducing risk of copy/paste error and slightly less readable representation
    * Discussion of copy/paste error: would need knowledge of the encoding by the user to copy only the principal; a new user to the ecosystem would typically copy the principal including the checkum as it looks like visually belonging together
    * Ben: problem with "." is that user can clearly visually separate the parts; in that case, he would prefer to intentionally confuse user on which part is the principal, if the principal should be a valid encoding on its own
    * Roman: parsing becomes hard, principals don't all have the same length
    * Milind: This has a high semantic burden on user
    * Levi: original textual encoding option also shows the principal, but without the checksum characters in the beginning
      * Comment: not sure whether this is true as every character represents 6 bits
  * Continue discussion in the next meeting
  * Roman: should allow principal as subaccount
    * After some clarifying discussion, Roman might think the proposal could be OK
    * Not having checksum at the end removes the nice property that the first and last characters have most information on the whole encoding, however
  * Roman: how to deal with zeroes in subaccounts
  * Let's continue the discussion next time, this is too important to be rushed


## 2023-01-24
[Slide deck](https://docs.google.com/presentation/d/1J4RG6Dj2oFzOWTRbxh8J59I3iF49WSM1YoU92_vBMnM/edit#slide=id.g1cb864ea205_0_62), [recording](https://drive.google.com/file/d/1B04AtA-yMQcJdtFItb76dP48yAZkoiMu/view?usp=share_link)

The full discussion can be viewed in the video.

**Textual encoding format for ICRC-1 account addresses**

* Dieter presents the different options.
  * Not in the slides: For 4a/4b, a variable-length checksum has been proposed as a possibility.
* Note: Video starts directly after the initial presentation of the options.
* Jorgen wonders about privacy properties of the encodings.
* Austin and Dieter explain: It does not matter which encoding we use, as they all encode the same information. In the original ICP encoding we had better perceived privacy. We made a strategic decision to use the pair `(principal, subaccount)` unhashed, which does not give the perceived privacy of the original ledger API. Any useful encoding we choose for this information contains this information, thus they are all the same in terms of privacy.
* Timo: There is an early fork between Option 1 and all the other options. Let's decide on which of the two ways to go.
* Dieter clarifies why we went for other options than 1: Option 1 does not have a human-readable representation, it is much harder to work with.
* Mario gives the example of the dashboard: It was tedious to work with the Option 1, which is currenrly implemented. He agrees with going for a human-readable approach.
* Roman: Another nice property of a human-readable representation is that it implicitly sorts the accounts by principle, which is very helpful because related things end up close together.
* Matthew brings up a concern: Hand-craftability may not even be desirable in the future.
* Dieter clarifies that among proposals 2-4b, there are other options that are not hand craftable. When eliminating Option 1 now, the only thing we lose is the lack of human-readability.
* Levi: Most important to him are checked subaccounts. No strong opinion on whether "simple" subaccounts can be unchecked. But complex subaccount with the first characters of 1, 2, etc. could still be miscopied.
* **The working group agrees that we can eliminate Option 1.**

* **Option 2**
* Dieter: Eyeballing the principal when comparing is harder in Option 2 than in other options because of encoding in character case.
* Ben: Thinks is not even correctly represented. Cannot compare principals across subaccounts.
* Austin: Principal is checksummed itself already.
* After some discussion the group comes to a conclusion:
* **The working group agrees to eliminate Option 2 as well.**

* **Decision between Options 3, 4a, and 4b**
* Dieter reiterates the essence of the option 3 
* Austin: Is it fair to say 4b is hand craftable?
  * Dieter: If you want to hand craft a checksum without a tool: no.
  * Ben: not being handcraftable is not necessarily a bad thing
* Dieter: uniqueness is not a big thing to be fair; whenever you want uniqueness, you can normalize the representation in other options easily.
* Could it be a big thing that people copy/paste non-checksummed representations that were not intended for copying, e.g., from a block explorer?
  * Ben: Strong opposition against variable length checksum. Adds complexity for not much benefit. We should have fixed-length checksum.
  * Medium-strength objection regarding optionality. Developers may start not implementing it and we could end up with ecosystem where checksums are not really used.
  * Medium opposition against 4a.
  * No strong preference for 3 or 4b.
  * 3 does have some nice properties.
* Timo: Always possible that programmer does not add checksum.
* Ben: Extra path in codepath, not a nice property.
* Levi: Uniqueness important to him, helps avoid confusion. Having more than 1 representation for one account is not a good idea.
  * What about the following: In Option 3, making property "checked" green and "hand craftable" red, would be perfect. Suggestion: What about taking the subaccount of 3 and add as last 4 bytes to the subaccount section a mandatory checksum, even for simple subaccounts.
  * Dieter: This is almost option 4b (N.B.: there, the checksum is in the middle, and may or may not have a separator, details t.b.d.).
  * Levi: Could leave it even without a separator, at end of subaccount, as checksum over principal and subaccount.
  * Timo: If there is no separator and small subaccount ids, would that not be confusing?
  * Austin: Just having one separator implies simplicity over having 2 separators. Do like only having 1, but might complicate it.
  * Mario: Prefers 2 separators.
  * Are we sure we don't want the ability to hand craft small subaccounts? Can get them wrong but it is 1 or a few digits only. For big transfers, copy from a wallet anyway.
  * Roman: Think it's nice in general, but is easier to have a tool to compute the textual representation. They have this for Bitcoin, for example. Much more important to have unique representation. Should not have options, but one unique way to represent it.
  * Timo: Uniqueness required for lookup, easy to do. Developer needs to do it. Block explorer removes checksum to get it unique, for example.
  * Roman prefers no optionality at all.
* Discussion that block explorers need to normalize the representation for their use anyway, otherwise it would be an incorrect implementation. Block explorer could present all addresses with or without checksum, depending on user-settable toggle.
* Levi: User may be confused if putting in account id and page loads with different account id.
* Timo: Where in the lifetime of account address do you want a checksum as you need it, and where is it required. Only needed where there is a human involved, e.g., when copy/pasting it. Even when using QR, it is not required. When reading on block explorer or tracing tx, a checksum is rather counterproductive.
* Ben: We cannot expect developers doing an app to figure out exact user path, there can be always new ways of doing things. Eliminating issues here eliminates problems.
* Roman: The fewer options we give to people, the less they can screw up.
* Ben: Option 3 has embedded checksum as advantage.
* Levi: Leaning towards 4b, with mandatory checksum at the end. 2 separators would be fine as well. Prefers colons as separators.
  * Roman: Also likes this idea better. Not sure about dash also, principal has dashes as separators. Should have 4c with checksum in the end without the dash.
* Dieter: Let's make main decision first, and then go into details: Optionality and handcraftability. 3 or 4a or 4b.
  * Jorgen: Hand craftability might even be an anti-pattern, one should maybe not be able to do this. Important to be able to eyeball the encoding. Not encourage anything else than copy/pasting it.
    * Roman: Fully agrees.
  * Austin: As prior art, both principal and human-readable version of account id has checksum, does not know of anyone sending money to completely wrong place. May already have a good starting point by having checksums already on individual elements.
  * Dieter summarizes that Option 3 does not have much support.
* Norbert brings up Option 1 again: Is it a good idea to have a checksum for everything?
  * Mario: In Option 1, the principal is not readable at all.
  * Roman: Most important that the principal can be seen. This helps a lot already. If searching for principal on web page and can see all accounts of it, this is also extremely valuable. Either is not possible with 1.
  * Other options than 1 have a checksum over everything, this is not a unique property of 1, whereas opaqueness is.
* Matthew: What about checksum only when subaccount has a certain complexity.
  * Roman: Problem that if prefix is copied, goes to wrong account. Cool part of checksum at the end: many web sites shorten the account to first and last bytes, so we get most amount of information about account in this way. Referring to Option 4b with overall checksum at the end, which has the principal checksum in the beginning and the overall checksum at the end.
* Dieter: We gravitate towards 4b, there is rather strong opposition by some people against having the checksum optional. Seems 4b is preferred option by the majority currently.
  * Timo summarizes about giving up optionality: When sending to "simple" subaccount, need (online) tool tool where one can paste in components and it computes the encoding.
  * Ben: Option 3 was intended to not require such a tool when crafting small subaccounts.
  * Timo: Clarifies that he gives up his preference for optionality of 4a and is fine with 4b.
  * Dieter thinks most people now gravitate towards 4b.

* **We run a poll on 3, 4a, 4b (4c is included in 4b)**
  * 3: Checksum encoded as part of principal, hand craftable
  * 4a: Optional explicit checksum, hand craftable if no checksum
  * 4b: Mandatory explicit checksum in the middle or the end (details t.b.d.), not hand craftable
  * N.B.: Some people interpreted 4b as mandatory checksum in the middle only and voted for 4c (mandatory explicit checksum at the end) as other option
  * **People very clearly prefer 4b (or 4c).**
    * No vote for 3 or 4a
    *  **Everyone prefers 4b (or 4c): mandatory checksum over everything in the middle or at the end**

* In the **next meeting**, we have to discuss the details of representation:
  * checksum in the middle or at the end;
  * if, and if so, which, separator to use for the checksum.
* Jorgen wants to discuss also whether a principal alone is valid.
* Mario announces that we have released the new ledger with the ICRC-1 interface. This means that now the ICP ledger and SNS ledgers all support ICRC-1.


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
      * Even if types do not match
        * If success, it uses the value
        * Otherwise, sets it to null
  * Mario notes that variants are much easier to use then records in his experience and strongly advocates using variants, according to his experience
  * **Decision to use extensible variant instead of the record, everyone agrees**
    * Cleaner
    * Easier to use in code

* Philipp expresses a strong feeling that we need a filter option when reading data from a ledger's archives
  * Otherwise, we need to retrieve all data of all archives and filter at the client
  * Filter is used to specify what kind of transactions we want to have
  * Opportunity to pass more filter options per transaction type
    * Want to receive mint transaction for specific account
    * Or transfer transaction for specific account
  * Otherwise need client-side filtering, but too much data for this (a single archive can hold gigabytes of transactions logs)
    * Or build index canister
  * Roman mentions that the problem is that the ledger cannot filter as it does not have the transactions and does not have an index; only has balances and pointer to archive
  * Philipp: We could do same filtering on ledger and every archive canister to get a filtered response
    * Use is most likely within wallets to display transactions to the users
    * Mostly clients would want user-specific transactions
  * Mario: If want to have this on the archive, need to add an index
    * Every wallet would ask archives all the time and create heavy load and heavily drain the cycle balance
    * Want to have caching of information somewhere, e.g., for Wallets
    * That has been the reason for the index canister
      * Index canister fetches transactions from ledger and its archives once
      * Index canister could offer data in a fast way compared to ledger and archive
      * Index could comprise a set of canisters for very large transaction sets
    * Have the following options to realize an index
      * Keep only subset of transactions, e.g., last 1000 per user
      * Keep full list of transactions
      * Keep pointers to transactions (done for NNS currently); when frontend asks for transactions, index canister fetches them from ledger or archives based on its index; index canister needs to be on the same subnet as ledger for this to be performant
  * Index canister that does not hold transactions and pulls transactions from archives is slow if not on same subnet

* Roman: Don't know in advance what you want to index
  * With arbitrary query support, would need database in every index that can efficiently answer all queries; all within the cycles limit and with multiple canisters
  * Goal of ICRC-3 was to have a means to obtain the transaction data
  * Can build index canister that syncs transactions you want, builds index you want, and serve queries to clients

* **Need a forum discussion how a wallet interacts with the ledgers**
  * ICRC-3 is not enough for wallet developers, need something more
  * This WG could work on index or multi-canister solution
  * Currently, most of wallets are building their own index canister

* **We should standardize also the API of the index canister to be useful**
  * Separate API for index canisters as accessed from clients
  * Maybe make it discoverable via the ledger
    * Client can ask ledger whether it has an index and ledger can point to it
  * Index canister must comply with index API, can be queries according to API

* 2 architecture options for index canisters
  * Make every archive also an index
    * Each archive becomes complicated; now it is 1 page of code
    * Ledger includes archive in its own memory, cannot have large codebase here
    * Nice that archive is a small, stupid component that stores blocks into stable memory and retrieves and serves them
    * Don't want archive to be complex, want it simple; don't want bugs there
  * Have separate index canister in addition to archive

* Index should not necessarily be a single-canister solution
  * Index may be huge for a large set of transactions
  * Many ways to implement different designs for this, for example
    * Everything in one canister that keeps everything
      * Ledger points to itself for index discovery
      * Ledger implements index itself and serves index queries
    * Index canister can delegate queries to smart archives or index helper canisters
      * Index canister is coordinator that uses further canisters; finds data for you
      * Coordinate distributed queries
      * Ledger points to coordinator for index discovery
      * Clients use coordinator as index canister

* Conclusion
  * **ICRC-3 still needed as a foundation for all index canister functionality**
  * **Current functionality of ICRC-3 seems sufficient for the foundation**

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
