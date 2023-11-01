# Ledger & Tokenization Working Group Charters


## 2023-10-31
Slide deck (n.a.), [recording](https://drive.google.com/file/d/1qc1iND7UXKG6l4eQtXdt-L3haMpnCQ-y/view?usp=sharing)

**ICRC-23**
* Dieter recaps the basic ideas behind ICRC-23
  * "Meta-standard" that defines namespacing, allowing ICRC standards to define HTTP namespaces
  * Nothing standardized yet w.r.t to canister HTTP interface
  * Goal: avoid clashes of namespaces
* Austin
  * This is mainly about deciding on a pattern tp apply and making sure it makes sense from relevant angles
  * Made [formal recommendation](https://github.com/dfinity/ICRC/issues/23#issuecomment-1787282250) to use `---` to indicate the ICRC namespace in the URL
  * Each ICRC standard gets a namespace using its number, see the [proposal](https://github.com/dfinity/ICRC/issues/23)
    * E.g., ICRC-3 could define HTTP API to fetch blocks: `https://{canisterid}.icp0.io/---/icrc3/block/53` for a hypothetical ICRC-3 method
  * Things to talk about
    * What symbol to use to separate the ICRC namespace?
    * ...
  * Typically, IC has separation betw. asset canisters and more functional canisters; nothing standardized yet
  * Avoid clashes: agreement required because global namespace is shared on the IC
  * Problem is if multiple standards define the same method, e.g., transfer, and they already have many users
    * Namespace collisions, lost composability
* Nate McGrath
  * No alternative suggestions to `---`, finds it OK to use
  * There will be follow-up proposals for HTTP standards based on this standard
  * Could provide best practice that HTTP specifications should be OpenAPI or Swagger
  * Could also establish best practice to apply REST best practices for API design
* Austin
  * SHOULD use URL patterns
  * Hard to come to IC that uses agent pattern as opposed to REST pattern everyone knows
  * HTTP tougher for POSTs as authentication problem needs to be solved
    * Could recommend header to put the signature in
  * Probably separate issue, more like a recommendation for applications in general that expose ICRC REST interface
  * Probably not for this WG to discuss this
* Nate: outside of ICRC, people should be able to implement whatever they want
* Austin: can make recommendation to follow some pattern, unless technical reason to not do so
* Dieter wonders about implications on asset certification and the trust team
  * Nate: thinks this should not have impact on either
    * Ideas for certification w.r.t. pagination, but only for single ordered list
    * Once when getting into sorting or filtering, it is hard / impossible to handle this with certification
  * Austin: could return data back as JSON, each JSON object has certification witness of data item; explodes data size
    * Then can just parse the JSON and certify each data element
    * More like RDF-style database
    * Question whether we have enough processing power
  * Nate: already possible if do hashing of individual items client side
    * Processing power more question for those who host gateways
    * Main drawback of above approach: if certify each element individually and return array of elements and ask gateway to certify each one individually, it is not able to assert that the correct items were returned, only able to assert that valid items were returned; replica could decide to return different items that should be in a filtered list; e.g., have list of 1000 items, filter them, get back 10 items: able to assert that there are 10 valid items, but replica could return 10 different items not included in the filtered list; has not been able to figure out how to resolve this
  * Austin: good point, not clear whether this is a solvable problem
  * Nate: Also have replicated query feature; this is better suited for this use case; on endpoint we want gateway to skip certification; with client, can replicate it multiple times and see whether canister responses match; probably better approach here; a little slower, but still much faster than update call
  * Discussion about zkWASM execution; outcome: cool technology, but not relevant in the near term; would be very challenging to apply this to ICP
  * Implications of certification for this standard
    * Don't need to take much of certificatio into account
    * Users SHOULD consider their certification strategy following the applicable best practices
    * Can go deeper in the scope of more specific implementations of ICRC standards; each standard will have their own requirements for certification
      * Simple ones maybe can do response verification out of the box
      * Other ones may require newer versions of certification
      * Some may not work at all and there we can use the replicated query approach
    * Guidance should be given in this standard
      * Nate: Would be possible to an extent
    * Nate: should not make any recommendations w.r.t. raw; wants to get rid of it
      * If there is endpoint that should not be certified with response verification v2, can tell to not certify; then this decision to skip certification goes through consensus; if raw, every replica can decide to not certify this endpoint
      * Want to make this transition as easy as possible
    * Austin: would not make recommendations on raw
    * Maybe sufficient: Everyone should handle certification following best practices
* **Next steps**
  * Dieter will provide a first draft PR of the standard (as time fits)
  * Austin happy to help to polish it

**ICRC-22**
* Length limit for accounts is still a problem
  * 128-byte limit defined by CAIP-10
    * Seems to be enforced in current implementations
    * Seems hard to change the standard now as it is final and there have been similar discussions from other people, so far without success of changes
  * Ideas
    * Cut out dashes
    * Use different encoding
    * Remove checksum
    * ...
  * Adapted representation would be a machine-readable textual representation
  * CAIP seems to have chosen 128-byte limit as rather arbitrary limit considered large enough
  * Ben: would prefer to cut out dashes as it is easier to add them back than the checksum
    * People agree
    * Ben to check whether cutting out the dashes is sufficient to be within the limit
  * Austin: Quantum-resistant principals in the future may be larger than CAIP limit
    * Standards would need to accommodate this
* Network identifier(s)
  * `icp:<hash of NNS public key>` (i.e., `icp:737ba355e855bd4b61279056603e0550` for ICP mainnet) is the right format to use for the network identifier, not `icp:mainnet`
  * The fact that NNS subnet recovery could result in a new key and thus new identifier is conceptually clean
    * Hard fork of the network in this scenario, even though the network state is unchanged; old network no longer operational, new network started with the same state
    * This specific scenario of NNS subnet recovery has not been discussed
  * Discussed that private, enterprise, testnets using IC protocol could be spun up and they should have their own respective ids in order to be addressable
* How generic should the standard be? Payments vs. generic method calls
  * Last time we said it should handle ICRC-1 and ICRC-2 transfer, approve, transfer_from, and not be fully generic
  * Maybe fully generic approach is feasible with reasonable extra effort
  * Dieter walks through [proposal](https://github.com/dfinity/ICRC/issues/22#issuecomment-1784947777)
    * transfer has 1 argument: `TransferArgs`; there are two viable approaches to encode this
    *   Candid-style encoding of each method argument, here the `TransferArgs`
    *   Canonicalizing each method argument (flattening out the structures), here flattening the `TransferArgs` record
    * Easiest is to extract a list of arguments and put them as query paramters in the URI: enough to cover important standards easily and similar to ERC-681
    * Completely generic may be not much more complex, standard could be very similar
  * Options
    * Candid encoding (generic approach)
      * List of Candid-encoded arguments; not human readable, but libraries in many languages available
    * Canonicalized representation of the method arguments
      * Arguments need to be decomposed recursively into their constituents and those must be query parameters
  * Both options allow for any kind of sequence of structures to be encoded
  * Seems to be agreement that it may not be too much harder to have generic approach when using Candid
  * Would be different to how Bitcoin and Ethereum do it
  * If using Candid, would not matter that account is too long as it's hidden in the Candid element
  * Problems with Candid approach?
    * Ben does not see issues
    * When crafting the URI one already does the encoding, maybe we don't want this
    * Would need to decode the Candid elements in the wallet to show fields (e.g., the amount) to user
    * Is there a good reason to have query parameters? URIs in principal use query arguments
  * Length limits of URIs: not in theory, but is implementation dependent
  * Candid designed to be concise, optimized for inter-canister communication
  * Candid would serve the purpose very well
  * Ben likes idea of using Candid
  * Would fee etc. already be contained or set by the wallet?
    * Timestamp can only be contained if URI generated on the fly; if static, not there
    * Optional fields can be left out without issues
    * Non-optional fields are harder to handle as they must be populated in the Candid element
    * In ERC-681, wallet can change anything it needs to change
    * Ben: Link should specify everything required, wallet can fill in other fields
      * Could be methods that a wallet does not know about
      * If want user to fill in something, e.g., the amount: provide static QR code everyone would use; should we have way to specify that certain fields need to be filled in by the user?
      * Problem: Amount not being in Candid element violates spec of `TransferArgs` as it is not `opt`
      * Ben suggests `field=<Candid type>` syntax, e.g., `amount=<nat>` (if angle brackets are allowed in the URI): the meaning of an angle-bracketed type is that the corresponding element must be provided by user; we need to check whether we can use angle brackets
      * Would need to set amount to `0` in the Candid-encoded element to be a valid encoding and the wallet then sets it properly based on the user-provided value
        * Unit value or dummy value for type: nat: 0, blob: empty blob, text: "" etc.
      * Ben: alternative: if we can have type that differentiates between flattened arguments and Candid encoding options being used, we can have both options available
        * `.../record/icrc1_transfer/list_of_candid_encoded_call_arguments` to have Candid
        * Flattened list of structures is not universal, is a compromise
  * Needs more thinking
* Next steps
  * Ben to check whether cutting out the dashes from the ICRC-1 textual representation solves length issue
  * People to think about the open points of the draft


## 2023-10-17
Slide deck (n.a.), [recording](https://drive.google.com/file/d/1G2dN3Vy0XQQx0R8TH4GRsTKdHaInceNR)

**ICRC-22: Payment requests**
* David dal Busco presents the proposal he wrote up earlier this year
* Other blockchains have standards to encode QR codes for payments
* Often used in dapps or exchanges like Coinbase
* Idea is doing something analogous for the IC
* Basic idea
  * Prefix the content with the token, but details t.b.d.
  * Address as defined by the ICRC-1 textual encoding
  * Parameters like amount to be added
* Prior work
  * Analogous work for Bitcoin, multiple standards there, one unifies everything
  * EIP-681 for Ethereum for both Ether and ERC-20
* Discussion
  * Canister id or symbol for referring to the token
  * Compatibility with [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-10.md)
    * CAIP is a way to specify addresses for any blockchain with a single standard; all major blockchains are more or less compatible with the standard
    * Currently, our address representation is a little too long considering CAIP-10 limits
    * Probably we need to change this representation to be compatible as the CAIP-10 imposes a limit for the address
    * CAIP-10 specification requires to specify a network and address basically
    * **Options** to address the exceeded size limit of ICRC-1 accounts
      * Use a shortened textual representation; OK as no one is typing it in and QR codes have error correction built in; we could probably omit the checksum; would be new textual representation
      * Remove dashes between character groups
      * Use different encoding for parts of the account
      * Trying to revise CAIP-10
      * Ignore length requirement imposed by CAIP-10
    * Expected that multi-chain wallets would use the chain-agnostic account representation for the QR code representation; this would be a typical use case
    * Levi: Wouldn’t adopting CAIP-10 require to change our account representation everywhere?
    * Ben: Checksum can be removed for QR code representation and added again once decoded if the application needs it; not ideal, but is a viable workaround
    * Dieter: Can we influence the CAIP-10 standard to make this field a little longer? Likely the limit is rather arbitrary for CAIP-10
    * Ben: We can propose, but the CAIP-10 standard is final
    * Ben thinks in CAIP-10 the length limit is not very strongly specified
    * Levi: Changing textual representation might mean changing it everywhere
    * Ben: We could also ignore the length requirement
    * Levi: We could reach out to the CAIP people to extend the limit a little
    * Dan thinks we should not ignore the length
    * Dan will reach out to the CAIP people and check what will be possible; he knows the CTO of WalletConnect; fairly certain they wrote the CAIP standard; approaching them
    * If we don’t succeed with the adaptation of CAIP-10, need to change our representation to cut the length down
      * Could remove checksum
      * Could remove dashes between the character groups: advantage: would not need to recalculate the checksum, only add dashed in known places
      * Essentially, need textual representation for machine and not human interpretation
      * Someone tried to change encoding from hexadecimal to base64; resulted in similarly reduced length
  * How to identify the token to make the payment in
    * Using canister id or token symbol for identifying the token?
    * Token could be represented by smart contract id of the token ledger; with token symbol, you might have multiple ones with the same name and there is no central registry; need to disambiguate; address would solve that
    * Chain id and smart contract; depending on chain id, the smart contract field is in an encoding according to the respective chain; would be x-chain compatible and would solve the token disambiguation
  * Amount
    * Use decimal points?
    * Most natural would be to use the base unit of the ledger account; e.g., on Ethereum 1 Ether is 1E18 wei (1 * 10^18 wei)
    * This would require a scientific notation (1E8 for 1*10^8) to specify the amount
    * Could use 2.014E18 to mean 2.014 * 10^18; combines decimal and scientific
    * This is how WIP-681 handles it
    * People like this
    * This is aligned with the crypto native way to express everything in the base unit
    * **Decision:** Allow scientific notation with decimal representation to make it easy to read and have amount represented in terms of the ledger’s base unit
  * Token principal / ledger address
    * Do we need to be chain agnostic, isn’t this IC specific
    * If put chain id first, does not make sense to be multi chain; chain id specifies already the chain and standards one needs to use; for Ethereum, they specify ethereum as schema
    * X-chain payments don’t fit in here; for Ethereum there is already EIP-681, for Bitcoin there are other standards being used; a X-chain wallets would use all of them, for the respective network
    * Gravitating towards an ICP-only standard because all chains have their own standard already; they are all very similar to this one
  * Ben: EIP-681 does allow one to specify a function name; would this make sense for us too?
    * Means it can capture any ledger standard and any function call
    * Ben: EIP-681 can specify encoding; for us needs to be encoded into Candid; not sure how
      * On Ethereum you can attach 32 bytes encoded somehow and it lets you specify whether it is an address or unit256
      * Frontend implementation is easy; if have function name and signature, know what to do
      * On IC, need to encode it into Candid; not sure how this works
      * Levi: Can encode method parameters into URI parameters
      * Can easily do this for transfer and approve
      * David: specification restricted to payments
      * Ben: EIP-681 is called payments; but is more general: executing something from within wallet; DEX can specify that if you scan a QR code, you make a token swap on their DEX; not sure how often this is used; need to decide what scope we want to have
      * Question on focus: payments or more generically any function calls; the latter may be a generic follow-up standard even; scope question to be decided on; seems like orthogonal extension to payment standard; getting simpler thing done quickly might be a good path forward
        * Roman commented in GitHub that he would like to have the approve method captured
          * If want approve captured, need to make it generic
        * Proposal: exhaustively specify few transaction types for payments for ICRC-1 and approvals for ICRC-2 now and possibly extend later if needed
        * People agree to this
      * How to capture method? Differentiate fields and add new transaction parameter; specify the fields for each supported method; extend later to further methods
      * We need schema prefix; icp:mainnet
      * From schema prefix they know it’s ICP and ICP mainnet; anything else can be inferred from this and interpreted
  * Token encoded as smart contract canister id; Do we want symbol there also?
    * Someone could lie about symbol
    * Not necessary to include in URI: consumer is wallet, can always verify and display more; can have internal registry of things; but if we require both canister address and token symbol, it is easier to phish the user as someone can spin up any canister; no need for human interpretability of URI
    * Agree, we should not encode the token symbol in addition to the canister address
  * Main open point is how to represent address compliant with CAIP-10 standard
    * Think already how to represent the address more concisely; another form of textual representation that is shorter
    * More information on CAIP: [forum post on CAIP](https://forum.dfinity.org/t/chain-agnostic-improvement-proposal-caip-for-icp/16957/23), [CAIP-19](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-19.md)
* Next steps
  * Dieter volunteers to update the specification
  * Dan to check with his contacts on lifting the length limit of CAIP-10

**Other work items to address in the next meeting**
* [ICRC-23](https://github.com/dfinity/ICRC/issues/23) might be something interesting to discuss next
  * For HTTP requests
  * Canisters expose more than 1 interface: normal smart contract interface and HTTP interface
  * No specification around the HTTP interface
  * Austin talked about specifying some semantics for this
    * Basically reserving some endpoints like metrics and specify common behaviour for canisters
  * Austin
    * Same issues w.r.t. namespaces as in function names in ICRC proposals themselves; e.g., if have same method name defined in two ICRCs, then cannot implement combo canister that has the same-name methods of both standards; have to pick one or the other
    * This would extend this idea to canister HTTP interface; e.g., reserve something under the dash; expose HTTP function or HTTP lookup, if service wants to expose JSON data (some Web API), we need to be able to define this and say how to do that to avoid collisions later
    * First came up with ICRC-3 to expose the ledger history as JSON
    * Probably some people around that know more about HTTP paths, construction of URNs, URLs, URIs, IRIs …
    * Would need to think about what is the best use case for system-based standard-based HTTP method exposures
  * David: Need someone from trust team in this discussion; suggests Nate from Trust team
  * Austin: Certification v2 coming out
    * Cannot currently certify every combination of skip/take in a pagination interface, for example
    * Maybe v3 would solve that; could have additional functionality for JSON data
    * Relevant for raw as well if don’t care about certification; just expose data; e.g., have ICRC that produces a payment QR code in the canister, so it’s easy to create certified QR code for payments; expose that through HTTP as a use case
  * David
    * /metrics comes to mind as a use case as well; DFINITY does this for governance …; get raw metrics data
  * Austin: maybe a symbol less used than “/“, e.g., “_” or “--“ that indicates the system root where ICRCs can put their stipulated endpoints
* [ICRC-4](https://github.com/skilesare/ICRC-1/blob/Icrc4/standards/ICRC-4/readme.md): Batch transfers 
  * Could talk about this also in one of the upcoming meetings


## 2023-09-19
[Slide deck](https://docs.google.com/presentation/d/1xQ2P8H-7D9PRuwV57lXEiK0Wzr9isMMD7AYOOEWylVA/edit?usp=sharing), [recording](https://drive.google.com/file/d/1PBwH3TBXoFx15_x3UiH4nhvsEA4IgY26/view?usp=drive_link)

ICRC-3: Settling the remaining issues
* Dieter walks through the pending changes to be applied to the ICRC-3 draft (see slides)
  * icrc3_get_transactions should be a query
  * ICRC2_Approve lacks expiration field
  * Renaming of icrc3_get_transaction to icrc3_get_block
    * No strong opinions in the group
    * The standard editors will liaise with the people having brought this up and make a choice for naming accordingly
  * Pruning of approvals
* Representation of transfer and transfer_from as ops (main topic)
  * Dieter presents the 3 options
    * (1) transfer op (and block); transfer_from op extends transfer op (current)
      * Simplest implementation
      * transfer and transfer_from are semantically equivalent in terms of balance transfers (the fact who initiated the transfer does not matter for this, but is only additional information)
      * ...
    * (2) transfer and transfer_from as different ops (proposal)
      * Cleanest theoretical separation between different operations: op code of the block unambiguously determines the operation at hand
      * Semantically equivalent operations in terms of a core aspect are modeled as 2 separate operations: not expressing semantic equivalences in the model
      * ...
    * (3) transfer_from expressed as 2 blocks: A transfer operation as the first block and the transfer_from operation with the additional field as the second block, with the second one having a reference to the first (another proposal)
      * Hard to handle w.r.t. fees as we would need to charge fees for 2 blocks now
      * Very inefficient because of creating 2 blocks (the approve already creates one and incurs fees, but is necessary; this would be yet another block that is not necessary)
      * Complicated as one needs to look at 2 blocks for a single operation
  * Discussion on whether it is likely that someone will know ICRC-1 but not ICRC-2 operations when releasing ICRC-3
    * ICRC-3 is released after ICRC-1 and ICRC-2; people know about both 1 and 2 when 3 will be released
    * Clients (e.g., wallets): For some ledgers ICRC2 has already been implemented, but not for others; so some may not have ICRC-2 support yet; expected to be a temporary case
  * Levi thinks both Option 1 and 2 work, but does not like very much the optional field
  * Roman: for new block type need actually 2 block types: ckBTC use case: if withdraw from ledger, approve to withdraw; minter burns funds, so this is a burn_from; thus, for Option 2, will need transfer_from and burn_from for ckBTC and other upcoming ledgers; hopefully never need mint_from
    * Option 1 is a simpler and much more natural choice for realizing this (add new optional field), Option 2 does not feel right
    * Approach through which we arrived there: Handle transfer_from first and handle transfer as special case without duplicating the code
  * Dieter: motivates that when viewing the options more abstractly, Option 1 also is the better choice because transfer and transfer_from are semantically equivalent in terms of a core functionality of the ledger; Dieter makes the proposal to rule out Option 3
  * The group rules out Option (3)
  * Dieter proposes to choose Option 1 over Option 2 and argues why he thinks this is the better choice (see slides, video)
    * Option 1 is better in terms of wallet forward compatibility (least worse option in that terms)
    * A strong driver for Option 1 is the semantic equivalence in an important category of transfer and transfer_from
    * Option 1 results in a simpler and sleeker implementation
    * Option 2 is conceptually cleaner
    * If we settle for Option 1, some things need to be made clearer in the standard
      * Don't reuse operations with different semantics
      * Provide guidelines for when to use an approach like Option 1 and when one like Option 2
      * Provide naming guidelines
    * If we settle for Option 2
      * We have worse forward compatibility
      * We don't gain much over Option 1
  * Discussion
    * Levi wonders how burn and mint would look like in Option 1
      * Roman: Burn is the same with an optional spender, transfer is the same with an optional spender; for mint we could not see why one would want mint_from; it feels wrong to delegate the minting to someone else
      * Levi likes this
      * Roman / DFINITY lean more towards Option 1 as this is the way that has been chosen for the implementation of all the ledgers
        * Much simpler from the code perspective
        * Much simpler from the indexing perspective: can easily index by account, for Option 2 we would have lots of duplicated code
        * Using Option 1 has helped a lot with implementation; otherwise would have transfer_from and burn_from blocks
      * Levi likes Option 1 and is OK to go with it
        * Should make clear in the standard that when adding optional fields that they don't conflict with optional fields of other standards; e.g., extension of ICRC-1, but use the same optional spender field to mean something else
        * Mario confirms that he will make this clear in the standard; fields defined by previous standards are preserved; they need to mean the same thing semantically, especially regarding the base properties of the ledger (such as the balances); e.g., if transfer says that from, to, account means a transfer of value on the ledger, this operation type cannot be changed to mean something else; of course, different non-conflicting operation types can be introduced
        * Roman suggests that the operation in the block could be prefixed with the standard's name
          * This is verbose, though, but might be OK if there are not too many optional fields (the base standard uses very efficient encoding anyway)
        * Mario: Extensions to ICRC-1 and 2 need to adhere to some rules, e.g., the ones outlined above
    * **The proposal of Option 1 is accepted by the WG**
    * Levi asks about optional fee and timestamp
      * Mario
        * Timestamp should not be optional, this is a mistake
        * Fee is optional and depends on the operation
      * Roman: usually fee in block is optional: if tx specifies the fee explicitly, we use that one; if tx omits the fee, block contains the effective fee that the ledger picked; by looking at the block, you know exactly how much to subtract without reading other ledger state; ledger needs to ensure that one of them is present
      * Mario will go over the proposal
      * Roman: idea is that tx field contains whatever user requested; use it to compute tx hash, deduplicate
        * Also want blocks to be replayable, if you look at the blocks, you have all the context required to rebuild the ledger state from scratch
        * We use the fee collector feature in a similar way: there is a block field specifying who should receive the fees
      * Roman clarifies that in the block there is an optional field effective_fee that contains the applied fee; set if the fee in the tx is missing
      * Timestamp should be always present (will be fixed)
      * Block timestamps are non-decreasing
      * Discussion on some details (see video)
    * Off-topic: Fee collector
      * In ICRC-1 and 2 the fee is burned; this comes from the ICP ledger that runs on a system subnet that does not need cycles; for other ledgers, you may want to collect the fee to pay cycles for the ledger (ideal situation of a self-sustaining ledger); fee collector is a ledger account that receives the fees
      * Fee collector block can change the fee collector account; from that point on, until the fee collector changes again, each subsequent block contains only the index of the block that defines the fee collector (saves space compared to storing the fee collector always)
      * Fee collection is different to minting account; minting account is special; want normal account for fee collector so you can do all operations you need; for SNS, you can send it to the account that is used to buy cycles
      * Trick used for fee collector for ckBTC, inspired by textual representation: account has same principal as canister, but subaccount is the subaccount "fee"
        * Subaccount is all zeroes, then "fee" in hexadecimal; so the fee collector account in ckBTC is canister_principal.fee
      * Fee collector could be another ICRC standard that extends ICRC-1 and ICRC-2 as it may be useful for others also
    * Levi: Limiting approval lifetimes: next time
* Changes to WG modality
  * Should have higher speed
  * Proposal to move more work to the time between sync meetings and work asynchronously on GitHub and the forum
    * Potentially have more than 1 standard being worked on concurrently
* Next topics
  * Signed transactions
  * QR code for payments
  * Indexing
* Mario / Roman to finish ICRC-3 spec following WG decisions
  * Then can push it towards voting and get it out


## 2023-08-22
Slide deck: n.a., [recording](https://drive.google.com/file/d/116qMOaILlRxaRrpri1DnH0u4hkGOSKh-/view?usp=sharing)

Due to only a few people attending, other topics of interest than ICRC-3 have been discussed.

**Privacy-preserving ledger**
* How could one get to a ledger (different standard) that does not allow anyone to read everyone's balances; this may be important to prevent people with lots of assets from being targeted in attacks
  * ICP ledger would be a step towards this
    * Attacker could only see information they should not get during the time they have access to a node and can read the blocks
    * Can query all balances of all account ids, but cannot trace them back to the identities because of the hash being applied
  * Can take the open source implementation of the ICP ledger and customize it (others have done this)
    * Would be easy to change the decimals, currently not used and only metadata
* Ethereum community is talking about cryptographic schemes to make this possible (stealth addresses)
* Maybe pre-signing transactions and sending the bytes might be a solution; anybody can send the bytes; this removes the caller; whoever can read the caller can read the from address of the transaction; that could go in the direction of stronger privacy; but public key needs to be visible, so can still know who the caller is, so this idea seems not to work

**Signed transactions**
* Now CEXs using cold storage need to create a lot (2 thousand) of transactions with different timestamps so that one tx will be submittable (the IC checks that the timestamp is in a given interval)
* Pre-signed transaction support at ledger level would solve this
  * Sign payload to the canister; an anonymous user could submit
    * IC does not validate, but canister
  * Payload, public key, and signature; then ledger can verify
  * Requirement is that payload must be deduplicated
* This would be really helpful to have as standard
* Could also be used as a cheque
* Should be discussed in the WG in the future
* Wallet canisters would be a good way also; there was opposition against this earlier
  * Ethereum is doing this now with account abstraction and smart contract wallets
* One question is what to allow to sign
  * Any payload? Very generic

Note: Generic tx signing in HW wallet (e.g., ledger) requires that content of what is being signed be displayed to the user

**Future topics to work on**
* QR code / URL for payments
  * Created for NNS dapp
  * Would be nice to have a standard on this so everyone can use it; likely less heavy than the current topics
  * Plan is to invite David
* Batch transfers
  * Sale canister of SNS could benefit from this; now is making a call for each transaction
  * Origyn canister sending out royalties could also benefit
* Indexing
  * Important topic as well; complements ICRC-3 (access tx log) with querying the ledger, e.g., by account
    * Basic indexing would be by account
    * Can do also by memo; different indices would be useful for different use cases
    * Must decide on how generic we want this to be
    * Consumers: e.g., block explorers


## 2023-07-25
[Slide deck](https://docs.google.com/presentation/d/1if2iZPLWSg6gV0siInuBBST_HXiLaVAfUlgGMdSse04/edit?usp=sharing)

* `icrc3_get_transactions` should be a query
* `icrc3_get_transactions` type may not be correct. It seems it's returning a function instead of being one
* Is the certificate just for the last transaction?
  * Yes, in order to verify a transaction you need the suffix of the log up to that transaction
  * You need to upgrade the certificated data every time you add a new transaction
* Right now transfer and transfer_from operations are the same ("xfer"). Would it make sense to split them in two distinct operation? This may set a bad precedent
  * The reason why we went with a single operation is that the spender is additional metadata that doesn't change the balance semantic of the transaction
  * Yeah but also the spender is never there for normal transfers and always there for transfers_from. The Ledger does give you back two different blocks that just have the same name and overlapping fields.
  * The issue with allowing to extend/override operations is that new custom standards may just decide to override a previous operation
  * e.g. "xfer" could be extended again and it would make it even more convoluted
  * It can be confusing but there is an underlying semantic in common
  * Another issue with allowing to extend/override operations is that indexing become more complex
    * I don't think so. Indexing work on fields and don't care about the semantic. They don't look at the opereation type.
  * If a client is verifying the Ledger then it needs to know the semantic in order to verify the balances
    * Yes, a client would need how a block would change the semantic but there is a common semantic for all operations, e.g. all of them have a fee
    * That's dangerous because you don't know about future operations. A new standard could override the fee field
    * You are not supposed to change the semantic of fields used by standards. You can extend but not change the meaning
      * This should be written in the standard
    * We should make it sure that operations and fields are reserved by standards
* The approve operation is missing the expiration field. Is this on purpose?
  * No, it's actually a mistake. I'll add it
* It could be an issue that new services may add additional fields and client won't know how to interpret them. Are we expecting wallets to implement every single possible operation?
  * A client should fail on unknow operation
  * What about known operation? Can we agree that "xfer" is always the same type?
    * Yes, we should make it so that the same operation has the same semantic
* We could change transfer_from to write two blocks, one with "xfer" operation that is a normal transfer and one for the additional field. In this way we keep the original "xfer" operation semantic without extending it but we know that is a transfer_from
  * We try to avoid writing multiple blocks per operation, it increases the cost and makes it confusing.
* Would existing Ledgers be able to support the change to operation for transfer_from
  * yes because no approve/transfer_from block has been written yet
* Let me talk with Ledger developers about the change proposed in this meeting.


## 2023-07-11
[Slide deck](https://docs.google.com/presentation/d/17h_7w3_yK2SdM2wOHW7Wkz8pCIxNN9AV7iioZNy0_iE/edit?usp=sharing)

* ICRC-3 draft published [https://github.com/dfinity/ICRC-1/pull/128](https://github.com/dfinity/ICRC-1/pull/128)
* Working group agreed on the draft
* Next steps
  * Forum post about the final draft
  * Next meeting the WG will vote the proposal
  * Topics for next WG meetings
    * [ICRC-22](https://github.com/dfinity/ICRC/issues/22) Payment format for QR code
    * [ICRC-4](https://github.com/dfinity/ICRC/issues/4) Batch
    * ICRC-5 Indexing
    * [ICRC-23](https://github.com/dfinity/ICRC/issues/23) URL Namespacing
    * [ICRC-24](https://github.com/dfinity/ICRC/issues/24) Presigned transactions


## 2023-06-27

[Slide deck](https://docs.google.com/presentation/d/18JV8Kb5G1-KeQAY92BMbM9CwAJV4Uey8V7vwZXpc6WQ/edit), 
recording: n.a.

* Dieter summarizes of where we are with ICRC-3
  * In the most recent meeting, Mario has presented a simpler solution than the one before:
  * Basic goal: Have a standard that allows exernal entities to validate a ledger
  * External entity can download the full history of transactions and validate them cryptographically through a hash chain
  * Problem: Ledgers can be implemented internally using different approaches; for example, additional fields can be added in addition to what is provided by the user; one example for this is the fee collector, which is an address to which the fee of a transaction goes; the ICRC ledger has implemented this such that whenever a user makes a transaction, the fee collector receives the transaction fee, but the fee collector is not part of the user's transaction input; it's rather added to the internal representation of the transaction by this specific ledger implementation; this might be different in different implementations of the standard
  * This creates the problem that for an external tool to compute the hash of a transaction is not straightforward
  * That's the core of the problem we want to address
  * Two meetings ago, Mario proposed a more complicated solution to this problem:
    * He proposed a schema which defines in a very generic way how to map or how to essentially hash a generic internal representation of a ledger in a canonical way, so that every external implementation could do this for a ledger. And this was perceived to be very complicated.
  * Simplified approach of most recent meeting:
    * This approach was geared at essentially having still a very generic value to encode all kinds of transactions, but to fix the encoding of the core fields that are needed for the transactions specified in the ICRC standard.
    * For example: burn requires certain fields like the two fields `amount` and `from and those fields and their representation would be specified in the standard, i.e., how are they represented in this generic representation and where you can find them so that you don't need a mapping for those basic fields.
    * This means everybody could easily build an implementation that can pull those basic fields from the data representation. But now the problem comes that the ledger still wants to have additional fields and those can be then encoded in a way that you put them as additional fields, for example, in a map. And those additional fields would then be hashed in a well-defined canonical way which can be derived by this schema.
    * This is now a compromise between the solution that Mario had shown two meetings ago and the idea of simplifying something. So it means standardizing a core of it, but keeping it still generic enough to account for internal representation details of different ledger implementations. And this is the proposal on the table.
    * What it means is that if there are ledgers around that do not follow the same encoding as proposed in the standard, they would not be compatible. And also to make it clear, to be fair here, the standard is based on the representation that the ICRC implementation of the ledger that Dfinity is building. So this is the basis for this standard proposal, which means that SNS ledger that Dfinity is building will be compatible with this standard. If there are currently concurrent other ledgers being built, they might use a different internal representation, therefore might not be compatible. But moving forward, every new ledger that's being built would follow this standard and would be compatible. So that's a compromise between being backward compatible to everything which we found to be extremely hard, if not close to impossible to achieve. In a practical way, this would be a compromise to be compatible to all the implementations that follow the way the ICRC-1 ledger implementation is doing it and moving forward. All new ledgers would follow this and also be compatible. So it's probably a very good compromise. It also allows us to move forward quickly. This is the other important part of this proposal.
    * And last time we had some discussions here about, I think some interesting discussions were about replayability of transactions. So for example, that the fee collector that the ledger would need to specify, would need to have a replayability semantics in the sense that you would need to, for example, know how the fee collector is implemented in order to be able to replay all the transactions in order to get this property. Which means you would not have things like the fee collector, for example, or certain things as part of an init block. So this is the idea, but it would need to be replayable at least.
    * I would say let's leave it with this here and continue the discussion from last time. So the big questions were or the big task everybody was taking home was to think about the proposal of this compromise solution, whether this makes sense to move forward with, and if not, bring up the points that hinder us from moving forward with this solution. So, summary, in short, again, having a core of the scheme be standardized for all the core fields of the transactions and having the rest extendable. Yeah, let's at this point open the floor for discussions and see whether people have found problems with that solution or whether it's a good way to move forward with.
* Austin asks for clarification whether one reason for this proposal is that it makes the standard compatible with the existing Dfinity ICRC-1 ledger implementation.
  * This is confirmed to be one pragmatic reason to move ahead with this. But it makes all implementations forward compatible. Non-compatible existing implementations can be made compatible with either of the following approaches:
    * Rewriting their history, which is complicated
    * Easier solution would be to put up a companion canister that would serve the new representation and rebuild the new representation from the Genesis block of the ledger onward
* The standard would define how transaction hashes are computed in an economic way and it would not be able to break things. So you can add anything you want. So it's very flexible moving forward. Really the only constraint is that the backward compatibility breaks if you don't use the exact same representation. That's the main point. So Austin, do you think it makes sense or do you rather want to raise an issue about this?
* Austin thinks the proposal is in line with what ICRC-16 proposes, the latter looks liks a superset of what is proposed here for data representation.
  * The map that we were using in CandyShared currently could be renamed to CandyMap or ICRC16Map or ValueMap or something like that.
* Austin: That allows you to map a value to a value as opposed to just a text. But I think that makes sense. But what you said earlier is the reason that I've been pushing for ICRC-16. Right. It's like the sooner we get a standard sort of dynamic candid representation out there, the sooner that people can use it because we're always going to keep coming back to the same thing. It's like, well, we got to be backwards compatible, right? And so as people create more and more and more going forward, it's nice to have a standard there that people can point to, to say, hey, we at least want to support some subtype of this if possible, if not the whole thing. That makes sense. And I think the ICRC-16 could be updated to be compatible with this, I think pretty easy.
* Dieter: Yeah, I guess we will need to evolve those two things in lockstep to make them compatible with each other. Now we still have the opportunity, but a very good point you raised. We should move fast with the CandyShared also.
* Roman: Future issue might be the subtyping works as expected. If we just return those things and then you try to decode them as like KMZ value, but at some point we might want to accept those values as well as inputs. For example, we have a plan to use pre signed transaction feature. Where can you sign your intent? Send it to the ledger, like from any place, and the ledger will execute it and the transaction you are going to sign is going to look as a value. And at this point you won't be able to pass candy anymore because it will have more variants than the ledger expects. So though subtyping works for return types, it won't work for input types. And if you want perfect compatibility, it should be the same type.
* Roman: Yeah, I get what you're saying, but as long as you know that you use a subtype, you use only the expected types. Can you go back one? I'm just thinking almost the one obvious thing that I see missing here is opt value. But I'm wondering if everything can sort of be broken down to these.
Our reasoning is that there is no need for opt because if something is not there, we just don't include it because the top level thing is a map. And if we don't have a field, well, we just don't put it in the first place. And then we don't need useless bytes with the field name and the null value.
* Mario: I think it's different. This value is different from what is a Candid value and that's what creates the confusion. I agree with Roman that when you represent data you send to a wire, if a field is not set, you don't set it to none, you just don't have it.
* Austin: Well, it depends right on just trying to think that I think that's right. I can't think of a use case right now where I'm thinking something along the lines of, well, if you wanted to let someone know that it was possible for that value to exist, but it doesn't. So the presence of an opt insinuates the intention, the purposeful intention of leaving it off as opposed to it just not being there. It could be some insinuation of intent on the protocol on the other end, which can be important when you have these dynamic structures. But I don't think that's a huge concern with these. I'm hoping that these ledger entries are fairly straightforward and fairly standard and almost ubiquitous. So that it's not an issue. I don't think so. Not having opt is, I think, fine. If you need a superset of these, you can always add an opt in if it's important. But I think this looks good generally.
* Austin: The one thing that I would say that I think we're talking about for for half a minute or so is the map. It is text to value. Is there any way in which you would need that it would be purposeful to have a value to value map if you say you need to record? I also don't see principle in here, which I guess you can always convert to a Blob. But subaccount, for instance, a subaccount is a complicated thing, right. So a subaccount has an owner and a subaccount. So you would have a value if you wanted to indicate as part of your transaction the full account ID, you would indicate, you'd have to have them as individual items in your map from sub account and from principal to your subaccount principal.
  * Mario: So you have a map with a field that is always there called owner, and then a field that may not be there called subaccounts. And then the value, both of them would be blops.
  * Austin agrees.
  * Mario: So the idea is to keep it as simple as possible while still being able to represent most of the data. That's why it's based on JSON and those kind of formats, a variant with very few options, but most of them represent what is needed. I actually would claim that even int64 here is bit of a stretch. It's not really needed.
  * Austin: Yeah, the simplest would remove int64.
* Levi: Yeah, so looks good. So each ICRC standard will define its own transactions, like the types of transactions that are part of that standard and the format for them. Is that what we're saying?
  * Yes, each ICRC standard name would be the prefix of the respective transaction, like icrc_1. icrc1_burn is an example, for the burn transaction. So we have a good name spacing to prevent clashing of names.
  * Roman: Not quite, because if we need to rename anything, any field, basically we have to recompute the whole history in the ledger. So the proposition is we take it as it is right now, or we have to come up with an arbitrary scheme, and then basically, if we touch at least one name, we don't care what the scheme will be. This is the same amount of work for us to change it because we need to rehash the whole history anyway. So that's the problem. So even renaming transaction type will require us to go and rewrite the history of all the ledgers, including updating all the archives and things like that.
  * Levi: I see you're saying the value of the op, if you change it, then you'll need to recompute the hashes of the value.
  * Roman: Absolutely. Yeah.
  * Levi: That actually might fit with what I was about to say, that maybe we can put the what do you guys think of putting the operation into.
  * Levi: Value outside of this value, like a variant field above this value in the transaction structure so that the people know how to decode the value? Because here the operation is within the value, but they don't know what if there's other types of transactions that don't have that operation field in it? Or will that operation field always be in every type of transaction?
  * Roman: It must be in every type of transaction. So basically how you decode it, you look at that. You look at the op field within the transaction, and then you decide how to decode it. Tag, basically, which you must always be there.
  * Mario: What's actually currently the problem that you want to solve, that currently the names are not aligned with the ICRC standard. What's the problem you alluded to with your statement, aren't we fine? Now, if we go with what we have, and that's what we have, we put this in the standard, it's a basic schema. And every additional field that people add, we don't care about, those are handled canonically through the schema.
  * Roman: Yeah. So my main concern is there is no name spacing in the field. I fully agree it's a problem, but the practical problem is that we cannot change anything without going for a costly, like very costly upgrade of multiple ledgers. To my mind, being able to ship things like in two weeks is more important than having the perfect naming and name spacing for the blocks. So I would prefer to keep things as is, unless they are horrible and unacceptable.
  * Mario: My point of view is that things are where they should be. We're already using this, so I don't think we need to change anything. But again, consider that it's based on our ledger. So we were proposing something that of course makes sense from our point of view. Those are all conscious decision we took for the ledger.
  * Roman: Just to explain why there are no prefixes anywhere is because we need to store those things. And if you add a five byte prefix, then every million blocks will be five megabytes of extra storage. 
  * Right. So it is the minimum number of bits for the internal representation here. Yeah, we don't have a problem. Everything is good.
  * Dieter: Yeah. Okay. So things in the interpretation, just to summarize the discussion, are very space-efficiently done. So I guess optimally, considering the information you guys had when you designed the ledger. So this is good. It stays efficient. It's what we want. Then this would be how we standardize it. And for all additional fields, people can add whatever they want.
  * Levi: Yeah, I think it's okay to just leave the ones that you guys already have as burn, mint or transfer, and then those will be like the legacy ones that we could just standardize and then all future transaction types, we can use the namespace if we want.
  * Austin: So is this a schema? Like, will this schema be served up by the ledger as kind of a type or an endpoint for the ICRC-3? As an ICRC-3 endpoint to give you the schema? Are we considering that?
  * Levi: No, this plan is to just standardize the transactions part of the standard.
  * Dieter: So an external application needs to be able to recompulate the hash. We need at least the relevant semantics for the external application to allow it to canonically recompute the hash for every transaction using the information it gets from the ledger. So does this require anything besides the information and the algorithm? Mario?
  * Mario: No, it doesn't. The schema is effectively fixed.
  * So the schema is essentially implemented as part of the algorithm you would implement to hash it, right? Yeah, canonically transforming this data structure. You get into a string and then hashing the string with a given algorithm.
  * Mario: Maybe doing some padding as part of the standard. We propose to attach a CDDL file with the schema that Dynamic Edge can use for the blocks. At least a start schema.
  * Language for concise binary object representation, just to give some context. So we decided to use exactly the same data types as we use in the public spec of the Internet computer to encode ingress messages and to use exactly the same hashing algorithm right there. Which kind of makes it unimportant how you order fields. You can move fields around in any way. It's like you will get the same hash. You can even recode your message in a different format and convert it back and do weird stuff. You'll still get the same hash back as long as you have exactly the same logical structure of the message. So we decided to use that, and within the ledger we use CBOR to encode those things. That's why the schema is in CDDL, but it doesn't have to be. We can come up with any schema language as long as it allow us to express the structure of the transaction.
  * Austin: Makes sense. I don't know if it's helpful or not, but I'll put in here a link to stuff that we worked on around schemas, if at some point it is useful to declare it and candid what these things are going to look like. But I get it. The CBOR, you want it stored as compactly as possible and you want your algorithm to be run over it where it's standardized and in an order that makes sense.
* Levi asks about replayability
  * Ben: We should further specify that in the blocks, anything that would result in a different replay result. So anything like setting the fee receiver, the fee recipient, or change of the minting account or whatever similar functionality that an ICRC-1, -2, -3 compliant ledger decides to implement. In the future. We should specify in the ICRC-3 standard that those kinds of operations would need to be recorded in the blocks. So not just specifying what the data structure looks like, but also specifying what needs to go in as a block. To make it 100% replayable. Because if you don't record, for example, the fee recipient and you change the fee recipient, then different fee recipients assumptions would mean that there would be different results.
  * Dieter, Ben: You can do it in those two ways: either it's explicit on the blockchain or it's implicit as defined through the algorithm. But that means the algorithm will need to be updated.
  * Levi: Sounds like a good idea to do that. My guess is that the ledgers so far have not changed their minting accounts or fee recipients. So it looks like it would still be possible to do that for all the existing ledgers too. So in that case, we define a transaction type for changing the minting account or changing the we don't need to.
  * Dieter: Define this in the standard, understand, but you just need to say that in case somebody requires such information, like, for example, for the fee recipient. If somebody has a feature like the fee recipient and this can change over the lifetime of the ledger, then there must be a transaction type to account for this. And then the algorithm of the ledger or the semantic of the ledger itself would define how this block is called and this transaction type is called. But this wouldn't be part of the standard. Right? This would be part of each ledger.
  * Ben: Yeah, it wouldn't be part of the ledger standard. Like there is no unified way that you define that. But you need to define two things. One thing, which is the algorithm for the reconstruction, and the second thing is the actual blocks. And when you combine these two, there can be only one interpretation.
  * Discussion: ICRC does not specify minting account at all, it's an implementation detail. The minting account can be changed on an upgrade. Everybody needs to know that this has been done in order to be able to reconstruct the ledger's state correctly.
    * Roman: It will be different transaction type. There will be a transaction type. I mean, if you send to the minter address, we encode it as a burn. So you don't need to know who the minter is.
    The transaction chain allows you to recompute all the accounts. But one thing is, for example, how we implemented the fee collector. You can recompute the correct accounts, but you need to understand the new fields in the block. So if you look at the block and some new fields you weren't aware of or their semantics, you will compute wrong accounts, like account balances.
    * Dieter: Right. For example, if you change the minting account at some point, thanks to a canister upgrade, then this would be part of the semantics, how it works, and everybody needs to know that in order to be able to reconstruct the balances. Then you would say up to a given block you use one fee collector account, starting with this block you use this another fee collector account, then you can still recompute the state of all accounts correctly. And now I think what Ben proposed is either you have this as part of the algorithm or you have such things explicit as a transaction in the blockchain and the chain of blocks for the ledger. And then the algorithm doesn't change, but it just uses the most up-to-date values from the blockchain. Those are the two things to get to the same result that everybody externally can recalculate the balances correctly. In one way they need to update the algorithm potentially. In the other way, they can read this update from this transaction that does a fee collector account update.
    * BenL Yeah, well, basically just that you need to have 100% verifiable.
    * Dieter: Yeah. So I think it's not a big thing to discuss now. I think this can be done either way. I think that's something that can find its way into the standard, we can discuss on the way there. But it's a good point to keep in mind. We need this replayability.
    * Roman: One thing is that adding new transaction types immediately breaks all the clients in wallets and so on, because if they see this new transaction type, they don't know what to do here, so they need an update before you can introduce it. There is a fine balance between keeping backward compatibility and replayability. I mean, we definitely want repliability. It's just how you implement it. There's optional fields which clients don't read if they don't care about them, or new transaction types. And then maybe you add the new feature and it immediately breaks all the clients.
* Austin: There has come up something multiple times what I call it the Ethereum assumption problem. Since a lot of people have experience with Ethereum and they kind of come to the IC with those assumptions in mind and something like a ledger on Ethereum you deploy it, you can't upgrade it, you can't change it. So there we don't have these problems. If we do something like say, you have to have replayability, then there's a whole class of potential ledgers that are no longer possible to fit into the standard. So if we do that, we not only sort of infuse these ledgers with replayability, but they also have to have sort of internally consistent.
Internally consistent, meaning they can't have any external dependencies. And there's theoretically a whole class of tokens that depend on things outside of themselves that they don't know. And so if you depend on something, for instance, say an interest rate that's held elsewhere, or an exchange rate canister where your token, maybe a transaction fee is determined by the external exchange rate somehow. Well, if that's the case, then you've got to at least translate what the reality of that exchange rate was into your transaction so that it can be replayed. And if it's an unknowable value, then you can't do that if that external.
  * Dieter: You raise a very good point here. But I wonder, wouldn't you in all those cases that you alluded to have this information encoded in your blocks so that you don't care how and where the information were created? Like the external exchange rate, or the creation of a fee and the fees in the block. So I think it's not an issue, but it's a good point to  look at. One question: Do you have a specific ledger in mind that might suffer from not having this replayability property? Or is it just a theoretical thought we need to dig deeper into?
  * Austin: I think it's just in theory at this point, but handling those is a different issue if we get to that point.
  * Dieter: I think we need to maybe look a bit at what ledgers we have or look a bit more at scenarios, whether there could be scenarios. Maybe we can come up with an argument to argue it can't even be possible to have that for any reasonable ledger.
  * Ben: But to Austin's point, I think a bigger issue we have is ledgers who have not recorded this information and in order to reconstruct words mean that they need to look at the block data.
  * Austin: I'll give a side example of what prompted me to think about this was there were a couple of comments on my ICRC-4 discussion by, I think, ICLighthouse who said that they thought it was a little too complicated and that we should just assume atomicity with ICRC-4 batch transactions. And my comment was that that may not be possible with the IC because if your ledger is internally consistent and you don't depend on any external information, you can do that. But if you have any kind of ledger that does depend on external data for each transaction, then you could potentially lose your atomicity because you've got a check for each transaction. You may have an await that could come back with different data. And so is it even possible to do atomicity with a ledger that might be set up like that? I don't know, but it prompted this thought in my head that at least the data that comes back, whatever you're dependent upon, whenever it comes back, you definitely have to record what you are dependent upon in your ledger to replay it. Does that make sense?
  * Roman: Yeah. I also strongly believe all the data should be in the log if you need to compute the balances or anything. Basically, and this is exactly what we do in our ledger, for example with the fee, because typically the fee is not specified. So what we do is if the client explicitly puts the fee in a transaction, you can find the fee in the transaction type like object. If it's not, then we include extra fields in the block saying what the fee was at the time of the transaction. Right. So you can always know what the effective fee was at the time and you can do it with all transaction types. And if you have multiple transactions to apply atomically, well, prefetch all the data you need in advance and then only then apply all the things atomically, something like that. I agree that this should be the property. I'm not sure we can specify it in the standard, we can kind of recommend it, but it's very hard to encode precisely what it means.
* Dieter: There's another question in the chat from Tomy Jaga: "Does this structure also apply to the approvals and permitted transfers? What I mean is, will there be new fields for ICRC approval and ICRC transfer from to store the data from those requests?" I guess those will also be part of the core standard, right, that we impose how it should be for everybody.
  * Mario: Yes, the answer is yes, because all of those things are essentially part of the core standard. That's why it would be imposed on how those should look like and everything you store in addition, you are free to call whatever you want and store in addition.
  * Roman: Furthermore, all new extensions that we propose will have to explain how they affect block structure. So if we have even more transaction types, we'll have to explicitly say how they will look like and what the schema of the block will be.
  * Dieter: Everything that's part of the ICRC standards that go into the ledger implementation that affects the blocks will be needed to be standardized in terms of format of all the operations. That's because the approach we are now going that we want to standardize all the core operations we have and the core data field and everything that's additional, you can do however you want to.
  * Ben: So for each ICRC number, we specify the core.
  * Dieter: For each new ICRC that would flow into the implementation of our ledger or of the ICRC ledger that anybody can implement, we will standardize how the corresponding respective types would be internally represented by the ledger in terms of the core fields. Correct? Mario and Roman.
  * Roman: Yeah.
  * Mario: So it will be the minimum set of fields required and the names.
  * Example batch transfers, ICRC-4 that Austin has been proposing, if this comes up, we would need to standardize how a transaction in internal representation looks like for a batch transfer, what the fields are and what the names are and the data types. And then as a ledger implementer, you can add additional things like a fee collector address, who receives the fee, things like this. Does this answer the question, Tomy?
  * Yeah, it does.
  * Tomi introduces himself: I've been working on some of the IC Motoko projects for like two years now.
  * Tomi: So if I get the answer correctly, all the approvals or any additional fees have to be standardized, right?
  * Dfinity: Everything becoming part of this ledger standard needs to be standardized in terms of the internal representation in order to be able to have these properties that everybody can essentially recompute the hash of a transaction from what it reads from the ledger and then validate the whole ledger. So, because that's the core property with the whole ICRC-3. So whenever we come up with a new extension to the ICRC ledger standard, like batch transactions, we have, for example, a new method that the ledger exposes, like batch transfer. This has a couple of inputs, like a batch of inputs. And then the ICRC-4 would need to specify this.
  * Tomi: Okay, so the current ICRC to each standard wouldn't include this. A new standard has to be created.
  * Dieter: Where would we standardize this internal representation for a new standard? In this new standard or an extension of ICRC-3? Currently there's no extensions of standard. Mario, any idea?
  * Mario: I would do it in the different standards because that keeps it extensible.
  * Dieter: Agreed, I think we don't want to change or extend an existing standard like ICRC-3 once it is out there. I think that's the important thing.
  * Dieter: It's five minutes to the closing of the meeting. It seems overall that we seem to have consensus on how we want to move forward with ICRC-3. Now, last chance to speak up if you think you are not in this consensus group. Otherwise, if we don't have someone speaking up in the next minutes, we need to take some next steps in the sense of moving ICRC-3 forward in the sense of creating a draft standard proposal on GitHub and then refining it towards something we can vote on and push into production. These will be the next steps. Now, does anybody else have an opinion on the current state on affairs? Anybody not?
  * Fine, moving on this way, otherwise I will propose next steps. Mario or Roman probably would come up with a draft for the standard, put this on GitHub and give everybody a chance before next meet, before the next meeting, to read through it and then having something much more tangible next time to say yes, this is really what we want to agree with. And then we have everything written up and less opportunity for misunderstanding. So we'd be very clear next time what we agree on.
  * Mario: Yeah, exactly. We're going to write on this proposal like a draft, and then we can discuss it again. At that point, everything will be already set. So we'll post the link so you can read it if you manage it before the next meeting, and then everybody can read it and see if it makes sense.
  * Exactly. So, last chance to speak up in this meeting. If we don't hear anybody speak up with an additional opinion, Mario and or Roman would move on with the GitHub based draft of the standard. Then, next time, we would have this draft as basis for a discussion. And ideally, we could already say yes, that's it, and more or less be at the point where we can have the standard more or less agreed on, then refine it to a point where it's final and then proceed with the formal voting and have it done. So, last minute, last chance. Let's give everybody minutes to think.
* Roman: One yeah, one last thing I wanted to say. It seems that we need the ICRC for the fee collector so that people know how it works.
  * Levi: Actually, I don't know how it works. So can you explain?
  * Mario: We never explained it. We can talk about it next time. But I agree. Let's talk about it because it's one of those things that we implemented in a ledger. We never explained that we were going to add it.
  * Dieter: Right. And it's an important part everybody will want in some form.
  * Ben: My question is, is there an implementation detail or does that need to go in an ICRC?
  * Dieter: Good point. Why would we want to have it in an ICRC? Good question. Why would we want that? Does it simplify or unify the client implementation? For example.
  * Roman: If you replay blocks, you need to know about these things to compute correct balance.
  * Ben: So every ICRC number would need to define how blocks are replaced. But not every implementation needs to have an ICRC number.
  * Levi: Just to address what Ben said before, the ones that do use the fee collector, we do need to specify it. I also do want to know how it works before I even say what I think about.
  * Dieter: Okay, then I think we are at time now. It's seven. Let's close here. Mario and Roman will draft what's currently on the table and circulate it before the next meeting. Bye, everybody. Thanks, everybody, for the great discussion and talk to you next time. Ciao.


## 2023-06-13
[Slide deck](https://docs.google.com/presentation/d/1tIvXbGAHoqwUtCt4AbhbJ2gzCalBzO73vquk6Ld69Ek/edit?usp=drive_link), [recording](https://drive.google.com/file/d/1ccyPjpj9q8pcKR7nSblWJYqS8-sSoRl-/view?usp=drive_link)

* Idea: Each ICRC standard can define their own transactions
  * In addition to what they define, they would specify how tx should look like
  * E.g., ICRC1_Transfer with its specified fields and values; new standard like ICRC-2 has its own new transactions like this one
  * The transactions that can appear in a given ledger is the union of the transaction types of all the supported standards
* Accessing tx log from another canister is easy
  * Argument: ranges of tx
  * Response: transactions themselves
* Accessing of transactions from outside the IC is harder
  * Making icrc3_get_transactions a query: efficient; but must be safe so that data is validatable
    * This makes ICRC-3 complex
  * Historically, ledgers on the IC work as follows
    * Ledger always certifies hash of most recent tx on the chain
    * Transactions are hashed together
    * Client can verify ledger by hashing each block (tx) and verify the certification on the most recent one
    * Challenges
      * How certification happens
      * How client knows how data is hashed and what is hashed
  * Hash is computed on data that the ledger stores; this is not necessarily the data in the ICRC-3 representation of the tx
    * Internal representation is optimized for space
    * ICRC-3 representation is optimized for usage
    * Internal representation can contain non-standard fields, e.g., for the fee collector which is one additional field to the transfer block
    * In ICRC-3 representation only the fields of the ICRC-3 standard may appear so that everyone can use it in the same way; clients work on all ledger implementations the same way
    * When calling icrc3_get_transactions, the ledger transforms its internal representation of a block to the standard ICRC-3 representation
  * **Proposal from 2 weeks ago**
    * Represent internal representation as a `value`
    * Value is type that never evolves or changes
    * Ledger should calculate hash of the blocks over this value in a standard way
    * Returns blocks to the user in the form of the value
    * This adds complexity to ICRC-3
    * Complicated schema that allows the ledger to declare how a block (generic transaction) looks like and how to map it to ICRC-3 transactions
    * Mapping from internal storage of the ledger to ICRC-3 representation
    * Ledger would need to describe how to perform such a mapping
    * Would make clients much more complex
    * **New proposal**
    * Still use the generic value
    * Instead of flexible scheme, some fields for each tx are fixed; those fields must always be there for an implementation
    * E.g., burn tx: hash and tx record; tx record comprises necessary fields: to, amount and op tag that indicates this is a burn operation
    * Proposal: all burn blocks of all ICRC-3 ledgers must have those fields in those places
    * Reason: makes it very easy to make a decoder; schema not variable any more
    * Still have ability to fetch transactions from outside IC and validate them
* Discussion
  * Transactions vs. blocks
    * Proposal
      * Should certify last block of the chain
      * Link together blocks with hashes
      * Think of batch transactions; much easier if we have blocks
      * Need to further look into this, not sure whether it is more efficient
    * Reason why not using block terminology: moving away from it
  * Main problem with proposal
    * Existing ledgers that don't follow this schema would need to do something else
      * E.g., have companion canister that stores the tx in this format so that the ledger can return this type of transactions
      * This should not be a big problem as there are not many ledgers out there
  * Note: proposal of schema is based on Dfinity's ICRC ledger implementation
  * We conclude that the very generic approach of the last meeting may not even work in practice, unless it is so generic that you can express essentially anything
  * Current proposal is a simple way forward
  * Is any user input included in the data structure?
    * This is up to the ledger
    * Should always have it, but not mandated anywhere
    * Tx hash would be calculated from this data; Rosetta mandates that tx hashes should be predictable
    * Tx hashes will be predictable, but not hashes of the blocks
    * If used in hash calculation, should be in tx input
  * Replayability
    * Ben: at least all relevant fields should be included in tx data structure
    * Anything that affects how you replay the tx should be in data structure
    * Logic used for replay is arbitrary
      *E.g., fee collector: can set fee collector to constant and have rules in logic how fee collection is done, but is out of scope of standard
    * Standard just says that some logic exists for replaying
    * Good ledger should do something like this anyway, without specifying how
    * Thinks that ledgers compliant to ICRC-3 should have replayability
      * Logical guarantees for anyone who is using the ledger
    * Implication: Fee collector is not part of tx, not in hash; if cannot be changed, replayability is fine; if it might vary, it should be part of the block data
    * Currently: Most ledgers don't store the init block, thus configuration is not part of the blockchain
    * This would require a separation of block data from tx data
  * This proposal is already very far progressed as it is based on existing implementation
    * Could be much faster with ICRC-3 if we go this route
  * If did not specify data type of account, ICP ledger could be compatible
    * But this would not be very useful as ICP is not compatible with ICRC block format
    * Account-id-based ledger can never fulfill ICRC-3
    * Could hash subaccounts of ICRC ledger as in ICP ledger and might become compatible with the ICP ledger; technically possible
  * Next steps
    * People look at the proposal and discuss more details next time


## 2023-05-30
[Slide deck](https://docs.google.com/presentation/d/1_UJIXPJF31LchhQjX1LMEMNA2OptnXkME8f7ZVPhaZ8/edit?usp=drive_link), [recording](https://drive.google.com/file/d/1zfTqWyQrIQeZ6_lmpDeLR-eQTZ7FbztT/view?usp=drive_link)

**ICRC-3: A standard for accessing the transaction log**
Proposal link?? is presented
* Terminology
  * Transaction
  * Submitted transaction: arguments provided by the user for a tx
  * Settled transaction: what is recorded on the ledger
    * Ledger may result additional information, e.g., record timestamp or record a fee that has not been provided by the user
* Transaction hash: hash of settled tx
  * Usually unique, only 1 tx in log with specific hash
  * Submitted tx not necessarily unique; we can have twice the same tx arguments
* Transaction log
  * Sequence of transactions, linked through hash chain
  * Allows 3rd parties to verify the ledger
  * Newest block in ledger is certified though a certified variable; client can fetch all blocks and verify the chain starting from the newest block
* Scope of ICRC-3
  * Access to tx log (main purpose)
  * Indexing
* Flexibility
  * Future, new block types to come
  * Need to support new block types in the future
    * "Untyped", JSON-like structure
  * Use this format to send block to client
  * Can define hash function generically for this structure
  * ICRC-16 about unstructured data interoperability relevant in this context
    * Could piggyback on this standard
* Main endpoints
  * icrc3_get_transactions
    * Returns vec of generic transactions (each generic tx has an id and value)
    * Archiving considered
  * icrc3_decoder
    * This is more controversial probably
    * Need to consider different implementations of the ledger
    * Decoder: each field of properly constructed tx can be found from value
      * Have well-structured type of a standard, e.g., ICRC-1
      * Have unstructured values, e.g., ICRC-16
      * Need mapping from unstructured to structured tx
      * Decoder takes input path for unstructured value and maps it to structured value
      * Anybody can write decoder that takes as input this data and decodes from unstructured to structured
      * Main issue: fairly complex
* Proposal to not use the term block, but transaction
* Levi: likes the genericity, but needs decoder clarified
  * Client (e.g., dashboard) needs to convert generic type to something that can be interpreted
  * Need to go from abstract value to a proper Rust or Motoko structure to be able work with data
  * Don't know how ledger will represent the value; different fields
  * Leave open; ledger defines its own decoder
  * Advantage over having ledger convert its own internal representation into the standard target?
    * Client may have different version, e.g., different fields; client does not yet know about a new field the ledger has
    * Decoding would have different hash than what ledger has
    * E.g., ledger has field called expiration_date, added to new blocks; client does not know; client can still decode when ignoring, but gets different hash than ledger because of field missing
    * With proposal, can guarantee that client always can compute correct hash
    * ICRC-1 does not even specify how to compute the transaction hash
  * ICRC-1 describes representation of blocks etc.
  * ICRC-3 specifies how the hash is computed on the data the ledger has
    * For this, introduce concept of unstructured data
    * Structure never changes, allows for encoding arbitrary structures
  * Roman's clarification
    * Have some ledgers already that use the values already internally and also a hashing scheme
      * Have way of validating the chain via checking hashes
    * Other ledgers have different representation
    * 3 Options
      * Take SNS or ckBTC ledger approach and put it in standard
      * Map existing blocks to new blocks without changing hash
      * Agree on better representation without changing meaning
    * Why we need schema: Need to be able to find data in generic data structure
  * Austin
    * Opportunity to build real interoperability infrastructure here
    * Exchange of unstructured data between canisters; can build on top of it
    * Not only trying to indicate fields that are necessary
    * If want to self-verify ledger, need to know data and hash function
  * Hash is generic hash over the value structure
  * For external integration, e.g., CEX, always used approach of verifying ledger backwards, starting from a certified chain tip
    * Go through hash chain
    * Query calls are much faster than update calls (reason for this approach)
  * Reason we need a this mapping is that ledgers can realize things differently
    * E.g., use different keys to store value (`from` ke yor `f` key in different ledgers)
    * Have no control over what ledger uses internally
    * If write dashboard for ICRC ledgers, it must work for all those
    * Need translation from internal representation to canonical representation
    * Only ledger can give us this mapping
    * E.g., `from` of transfer: need to know where to find this field in ledger's internal representation; different ledgers may have different values
    * Ledger calculates hash over internal representation (non-canonical value)
      * Is intermediate data needed to verify that
      * Once have verified correctness, convert to own representation and use it
    * If one would not have everything, dishonest client could inject any data
      * Need to hash everything that is stored
* For SNS ledger, went with following approach
  * get_transaction: returns well-structured txs, cannot be verified
  * get_blocks: returns hash structure
  * If someone does not need to verify, can get well-structured data
  * Both return kind of the same data, canonical that cannot be verified / non-canonical that can be verified; is definitely an approach as well
* Austin: Looks like there is a transform language comprising a hash function
  * Could have a query endpoint where you can download the program to populate hash
  * Program defines how to calculate hash oneself
  * As long as have library to run program, should be able to interpret data
* Need to think of how ICRC-3 is used (wallets, dashboards etc.; everything off chain)
  * Even if we split the API, clients still need to verify
  * Without verification, limited use, e.g., only verify payment
  * Splitting it is twice the work, duplicated get_transaction; two endpoints with same data
  * Rather propose this, can derive canonical data out of this
* Helix wants tx hashes to identity tx, also inside of canister
  * Even canisters might want to get the same data in different formats
  * Would be great to come up with one endpoint to verify structured or semi-structured data
  * Most useful for the ecosystem; schema for block in standard; how to hash block
  * Might also need to map values, not only paths
  * E.g., for type of tx: no list of standardized values
* If a single replica sends wrong result, client can detect this
  * Solved by the approach
* What if values are all in well-defined place and ledger can add new fields
  * Would break backward compatibility
* If have ICRC-1 transfer, must be unified for all the ledgers
  * Client can use that regardless of the ledger
* Even if ledger representation is standardized, what about people experimenting with new ops not explained in the standard?
  * Probably namespace those variants
  * If client does not understand operation, still gets a transaction, but don't understand
  * This might work in the end
* Keno
  * Working on an ICRC_2 and ICRC_3 implementation
  * Valuable to make more extensible, so we can have different ledgers supporting different tx types
  * But still want to compromise
  * But if want to extend canonical mint, burn, transfer, should not compromise how ICRC-1 and 2 canonicals are working
  * Rather customized tx type, added on to it and not throwing away canonicals
* Schema is map between structured and unstructured value
  * Ledger telling you that for icrc1_mint, you can find the amount in a specific field
  * Proposal is convoluted, but not too much
* Maybe have generic structure for backwards compatibility, but impose constraints for new ledgers
* Next steps
  * Improve proposal write up
  * Give people time to think about it until the next meeting


## 2023-05-16
[Slide deck](https://docs.google.com/presentation/d/1nQ7oWeb9Xk8CW1aXyP1vqMFMxI3xZRvovXu1SVN6lPo/edit#slide=id.g125c3b1bfa8_0_0), [recording](https://drive.google.com/file/d/1fv7W6Ibw6OlpRE5vcF1rZmd4hO44QVkW/view?usp=share_link)

**ICRC-3: A standard for accessing the transaction log**
* Mario presents thoughts on ICRC-3
* Resuming discussion that has been started some time back
* ICRC-3 has been evolving since the discussion of January 10
* Originally a standard for canister to query ledger and find blocks
* Meanwhile, ICRC ledger has been developed and focus has changed for tx log of ledger
* Use cases for a ledger's transaction log
  * Validate payments: notify recipient and give them the block id of transfer; they can fetch the block and validate the payment
  * Wallet apps: visualize information; main use case
  * Block explorer: visualize information
  * Ledger validation off chain: e.g., Rosetta node must fetch blocks of ledger to validate all transactions
  * ...
* Challenges
  * Support future standards: must be able to extend tx log with new transaction types
  * Different block formats of different ledgers
    * Additional fields
    * Additional data
    * ICRC-3 should not prevent this, but support it
  * Indexing: historically tx log is list of tx, but in reality we need also some indexing (e.g., for wallet app)
* Scope of ICRC-3
  * Tx log that only canisters can consume is not enough
  * Raw blocks API (one of the two main topics)
    * Access to blocks via block index
      * Range or set of blocks?
      * If have index canister that stores index of tx, but not the tx: can use set queries on ledger to query multiple blocks in one call
  * Index API
    * Could be addressed by ICRC3 as well
    * Raw blocks API is not enough for wallets and block explorers
    * Need some form of indexing to be useful
    * How to find indices of ICRC ledger?
      * Canister ids in metadata
      * New endpoints
    * Different fields by which one can index
      * E.g., also memo
      * Should the standard address this as well? Might be important to get tooling interoperable
* What is currently being implemented for the ICRC ledger?
  * How blocks are served
    * Blocks are represented as generic JSON-like structure
    * get_blocks: use generic JSON-like structure; client receives all info from server, regardless of fields; client receives full data when it receives a block
    * If fetch block, calculate hash, can verify without decoding
    * Works particularly well with off-chain applications, e.g., the Rosetta API
    * Endpoint takes starting point and length
    * Response is vector of blocks
    * Block data type is variant that is never changing; contains all fields ever required by using generic vector of values and a map
    * Nice for off-chain applications, not for canisters; canisters don't need to verify
  * Get transactions
    * For canisters
    * Serves a list of transactions, targeted at canisters
    * Defined as record that has a type; optional fields, only one to be defined; records are extensible, so new blocks can be added
    * For new tx types in the future, can add new field to record
* DFINITY's ICRC Ledger's index
  * Deployed together with ledger
  * Syncs blocks with ledger periodically
  * Basically is archive canister, but implements index also
  * Used by wallets; wallets don't use the ledger, but the index
  * Index is required to work with ICRC-1 ledger
  * Fetch transactions for account
  * Can imagine to add more indices

Discussion
* Roman: Should get to the point where we can implement reasonable wallet app; this should be outcome of the whole ICRC-3 discussion
* Ben: another use case: payments that can be easily validated on chain; unique, predictable tx hash, predictable before tx is submitted
  * ICRC-1 cannot guarantee that tx is unique because of fields; may have two tx with the same fields
  * Can have clash of hashes: can not guarantee that timestamp is always included, canisters usually don't include the timestamp
    * Is predictable, but not unique; can send the same transfer twice and get the same tx hash
    * Rosetta specifies that tx hash mush be predictable; we cannot populate any fields, as then it would not be predictable
  * Ben concludes that we have to live without uniqueness
* Levi
  * Basics / main point: see transactions
  * Indexing as additional feature is great; hard to see how to standardize this in a generic way; only for some simple use cases, e.g., indexing by account
* Matt: Who would be able to access the tx log? Concern if everyone can see all transactions
  * Tx data is public; need to make public for verifiability of ledger
  * ICRC ledger allows for everyone to query ledger; otherwise, it would be unverifiable; could not integrate with Rosetta either
* Blocks are hashed together, most recent block hash (the chain tip) is certified by the canister
  * Rosetta would fetch tip of chain with certified hash, verify it, and then fetch blocks backwards
  * Can get tip of chain with update call and all other blocks with query call for better efficiency
  * Could standardize this way to verify the blocks
  * Want to have wallet compatible with as many ICRC implementations as possbible
  * Want all ICRC tokens integratable with Rosetta
  * Hash: compute hash in predictable way; should discuss to have this in the standard
  * Scope of ICRC-3 is huge when including indexing and hashing
* Proposal to put forum post with concrete proposal up
* Bogdan: Can we split the scope into smaller pieces?
  * Design space for indexing is probably large
* Wallet integration is important to be considered
  * Especially indexing relevant here to have interoperability
* Roman thinks it's important to have the big picture when it comes to doing a wallet app; to not have a surprise that the block retrieval API makes indexing hard
* Need to move forward with the individual steps
  * Get blocks API, get tx API
  * Indexing API
  * Could be part of the same ICRC-3 standard
* Roman: huge issue
  * Block format and encoding decided by the implementations
  * If we decide on something now, we have those implementations around; not practically feasible to consolidate current implementations to new standard (theoretically possible, but would be a massive effort)
  * Tradeoff
    * Can come up with any format we want, will be compatible with data, but won't be verifiable
    * Or have verifiable format, but no one can implement it because they have come up with a different format already
  * Standardizing afterwards is too late; either use verifiable format or stick with what people already have
  * Migration is insane amount of work and coordination
  * Levi: is there something missing from what we have
    * Roman: Expects that other ledgers are different, and they will never be compatible; all existing players would be disadvantaged
  * We could also opt to not standardize the hashing
* Risk of canister controller modifying blocks
  * Blackholed canister
  * Modification history of canister (partially implemented)
  * People can sync the block chain and keep the history


## 2023-05-02

[Slide deck](https://docs.google.com/presentation/d/1rtYDv_fxUfg08oDx8SKaaBVHyGj8WOksR95QXeVB7po/edit?usp=share_link), [recording](https://drive.google.com/file/d/168t4RI3c1pQSO16AUnQgQQRTuDjPwR5L/view?usp=share_link)

**ICRC-2: Semantics for approvals**

Roman made a proposal as agreed in the recent meeting ([PR-109](https://github.com/dfinity/ICRC-1/pull/109))
* Dieter runs through the proposal of PR-109
  * Semantics of approvals closer to ERC-20
  * Override semantics for approvals instead of additive semantics or individual approvals
    * Advantages over previous approaches
      * Individual approvals are rather complicated to implement
      * Additive semantics was confusing: semantics for value was additive, but for expiration it was overriding; this is not intuitive
  * Allowance based on account ids, not principals, as proposed by ICLighthouse
    * Nicer implementation as account ids are used in all places in the ledger implementation anyway
  * Add compare and swap semantics for better facilitating concurrency of requests
* Levi recaps that his original proposal [Issue-93](https://github.com/dfinity/ICRC-1/issues/93) came from additive semantics: allowance was additive, expiration was override semantics: confusing; allowance can build up over time and lead to bigger allowance than wanted; needed to be solved
  * Proposal PR-109 solves those problems; allowance overwritten, not additive
  * Happy with proposal
* Matthew likes the proposed solution as well
* Austin finds the proposal fine as well
  * Biggest concern is that people can approve more than is in their account; but they cannot double spend, so it's OK
  * That's a general problem of the ERC-20 approve model
* Discussion on race conditions
  * Should not be an issue if the ledger is properly done
* Austin: likes the idea of going with the account id for approvals
* **Group consensus is reached on adopting the proposal PR-109**
  * **ICRC-2 is now finalized**
  * Next steps
    * Vote by WG on proposal
    * NNS vote

**ICRC method naming**
* Discussion on the naming of methods in ICRC-1 standard
  * Ben: Challenges whether methods should be prefixed with their standard name, e.g., icrc-2_approve; this requires everyone to know which standards each method comes from; rather use the base standard name, e.g., icrc-1, to prefix all methods of the standard
  * Austin things it is nice to have this separation done that each method is prefixed with its standard name, so you can pick and choose
  * Namespacing was a main driver to have the std name as prefix
  * Ben finds current situation confusing for people using the ledger
  * Ben: Substandards extending ICRC-1 could have ICRC-1 naming scheme
  * Austin: Could have icrc-1 function for each icrc-2 function that calls the icrc-2 function
  * Reason for current situation is namespacing
  * Levi: ICRC-1 is set, no going back; current situation is best that we can do as we cannot anticipate what is coming in the future; thus, new standards follow their own naming scheme; ICRC-1 is set, no new icrc-1-prefixed functions can be added
    * Having new icrc-1 methods coming later is confusing
  * Austin: namespacing functions is instructive in teaching people; likes that ICRC-2 functions are prefixed with icrc-2, sees this as an educational and conceptual feature
    * Having developers not know about extensions confuses them even more
  * Ben: wants to avoid that people need to know the prefix for each function as this is additional mental overhead
  * Timo: there could be a different allowance standard in the future, then it needs its own naming scheme
    * This was one of the main reasons to have the current approach
  * **Decision: rough consensus on keeping the naming as is**

**Upcoming meetings**
* Next meeting
  * ICRC-3
* Future work
  * ICRC-4
    * Austin: ICDevs has approval for exploratory work on ICRC-4 batch payments; want people actively participating in this group; bounty: create implementation in Rust that resolves many issues we would need to talk about so we can have speedier discussions on this
* Matt: additional functionality: lend function, also for fungible tokens; e.g., for gated communities
  * Use case, e.g.: access some service when holding certain amount of tokens
  * Discussion
    * This would mean that we differentiate between *holdership* and *ownership* of fungible tokens; currently, we only have ownership which implies holdership
      * Retain ownership, but give holdership to someone so they can use tokens for some purpose; would be more long-term than a flash loan is
    * Could potentially be solved with wallet canister
    * Matt thinks there are plenty of use cases for having the holdership status for tokens; essentially loaning
    * Austin: if we have this generically, one may eliminate tokenomics where exclusive ownerhship is the driving force
    Matt: Could have lend function that returns tokens after some time
    * Escrow can solve this (Matt thinks this mutates ownership, which is not what is intended)
    * Would need distinction between is_owner and is_borrower
    * Austin: problem of infinitely reducing time frame
      * But apps can mandate that lending be for min time
  * Ben suggests that Matt propose this as standard if he thinks that it is generically applicable


## 2023-04-18

[Slide deck](https://docs.google.com/presentation/d/1LpfMQsfJRJczmthUVxWBCbpDKVJv-JvDtG22HNJXMI4/edit?usp=share_link), [recording](https://drive.google.com/file/d/1ukhkNrgfAODLyaY7OGxVR3BA5tyu7wv7/view?usp=share_link)

**ICRC-2: Semantics for approvals**

* Questions to answer: Do we want expiry semantics and, if so, which?
  * Is the additional complexity worth it?
* Didn't receive much input from the community on this in response to our post
* Mario: Technically, don't need expiration, can remove approvals manually
* Ben: feedback from ICLighthouse
  * OK with expirations, but no separate approval id for this
  * Approvals should be account based, not principal based: as we are using accounts as first-class citizen, we should stick to this scheme everywhere; approve_to would be to an account; signer would be a principal
    * The spender must spend as canister id / subaccount pair, although subaccount is not part of signature; still part of parameters you use in the transfer_from; making a distinction between subaccounts
  * ICLighthouse think a lot about use cases where both parties are canisters; this would remove need for separate approvals, can approve to different subaccounts of principal
  * Levi: Expiration is an orthogonal problem
  * Ben: Expiration is two things:
    * Ability to set different expiration for different approvals; this is included in approval to pair of principal / subaccount
    * Semantics of expiration, which is orthogonal to what has been discussed here
  * Levi clarifies that in his proposal, spender does not need to know about approval id
* Use cases
  * Better security for user and better control is key to Levi's approval approach
  * Expiration particularly important for IC as canisters are mutable; that's why mandatory on ICP; trust model is different
    * Expirations can limit exposure to risks to shorter time; mitigation, not a guarantee
  * Buying stuff; only approve until end of a sale
  * Buy chat tokens, know purchases and approve only for limited time
  * Main difference to cancelling is that the latter requires remembering doing it; better if canister does it by expirations
* Andre from Decentralized Trade introduces himself as a new WG member and presents their use case
  * Building wallet on IC, solving real-world trade issue
  * Tokenizing cargo, anything B2B transactions
  * Using stablecoins for settlement
  * Cargo tx / money tx via stablecoins; everything done on chain
  * Use case:
    * Currently implemented as escrow: buyer deposits into escrow; when ownership transfer of cargo happens, withdraw to seller
    * Might be doable without the escrow: buyer would approve deposit, money would be withdrawn from account; security of seller: money should be blocked at buyer's account until tx happens
  * Roman: Locking of the funds is currently not part of the approval mechanims; tricky; it is not even clear who funds belong to while they are locked
  * Ben: Could lock without revealing subaccount you have approved for; when unlocking, send message to approved party which subaccount you have approved to; Roman: does not work: can just look at the chain for seeing the approval
  * Roman: timeouts and expirations do not solve this problem; expirations are nice for UX, but don't solve fundamental problem
* Question on whether we should have expirations
  * Mario thinks expirations are not really needed, but make it easier for the user
    * Is it worth the additional complexity?
    * Cannot think how user can know how long to set expiration date for
  * Levi: expiration helps whole flow; if expiration is there, user can approve for a given time
  * Roman: not convinced the complexity is worth it in terms of UX benefits
  * Matthew gives another security-based motivation for approvals
  * Ben: most use cases would not be that canister asks to withdraw; rather, make approval to avoid 2-step transfers; but when making approval, want better security semantics than max-amount blanket approvals; this would be 90% of use cases
  * Mario: likely hard to set the proper expiration time
  * Ben: approvals are UX improvement, in practice no one remembers to cancel approvals manually
  * Mario: probably wallets would need to perform cancellation of approvals
  * Ben: none of the wallets have this functionality currently
  * Mario reiterates that he is not fully convinced we need expiration
  * Matthew: the more time attacker has to harvest wallets, the stronger an attack they can make; expirations reduce exposure
    * Think of someone with a multi-year attack plan, harvesting open approved amounts
  * Ben: could set default value to e.g. 30 days
  * Roman: also thinks that we could have a default expiration, if you want to expire earlier, need to specify; this would not add a lot of complexity; other use cases: expiration is maybe not best way to implement them; maybe focus on specific use case of safer payment flow and have expiration as extra feature
  * Roman: Wouldn't pre-signed transactions be a replacement for approve and transfer_from?
  * Ben: No, is still a 2-step transfer; having pre-signed tx is no guarantee that tx will go through
  * Discussion on pre-signed transactions as a new feature
  * Dieter summarizes that the potential feature of signed tx is not an exact replacement for approve / transfer_from: with signed tx, the precise transfer amount is specified upfront, with transfer_from only at the point when the transfer is made
  * Roman: agrees, not equivalent
    * Likes expiration, but maybe should limit scope to have it as simple as possible
  * Levi: not having expirations is also that approvals can build up over time and spender having huge allowance without approver catching up with the fact that this happens
  * Mario: we could expire all approvals after 30 days
  * Roman: that still does not solve the problem; could keep it one global approval, remove additive semantics; most do not need the additive semantics; was required for canisters making approvals in the context of concurrent requests; if we want to keep it simple, we should keep same semantics as Ethereum network; set amount and expiration, overwrite previously set values; if keep additive semantics, need to do same complexity with approvals; we could use this simpler overwrite semantics and design different system for canisters; limit scope of this feature to interaction of frontend and canister
  * Mario agrees with Roman that is is crucial to to keep things simple; lots of discussion so far, complex to implement
  * Levi: would be OK with overwrite semantics; thinks that pre-signed tx is very cool idea
  * Mario: pre-signed tx: important, but not full replacement for approve / transfer_from
* Overwrite semantics would be much simpler to implement
  * No negative approavals
  * Not multiple approvals, but only a single approval, to consider when transferring
  * Overwrite is like ERC-20 semantics
  * Same model as Ethereum
* Roman: Main downside of previous model of additive semantics with overwriting expiration is that it is confusing; approve one amount, approve again, extend expiration to the future, amount can build up; unexpected behaviour; as developer, would expect independence in all dimensions: amount and expiration; confusing to have overwrite for expiration but not amount
  * The subaccounts requested by ICLighthouse can help solve not having additive semantics
  * Subaccount makes code cleaner as we use account ids everywhere; in blocks have account ids
  * Extra subaccount would be helpful to keep the block model clean
* Roman: If we use overwrite semantics for amount and expiration and approve to principal / subaccount, approvals to different subaccounts of a principal woult be independent approvals with their own expirations
  * Removing additive semantics is more bearable with the approval being for principal / subaccount
* Mario: Could add optional field that is checked when changing approval; change approval from 10 to 5 with new optional field; if field is set, additional check against the value of current approval
* **Following the discussion, Roman proposes**
  * Overwrite semantics for both amount and expiration
  * Subaccount feature of ICLighthouse, as this reduces problems of not having additive semantics
  * Optional field for realizing compare and swap semantics by checking against this when changing approval
* Next steps
  * Roman drafts the proposal
  * People think about it until the next meeting
  * We come to a conclusion in the next meeting


## 2023-03-21
[Slide deck](https://docs.google.com/presentation/d/1sOj9HEcnn_p9m1Xh1jlLfOFMB0KIUs9Lvy1XBwFE3qk/edit?usp=share_link), [recording](https://drive.google.com/file/d/1YNzDNZFlGcqcaGabXAClXqnYrZsHLigi/view?usp=share_link)

Sam / Samer joins the WG; he is working on a Motoko book and decided to join the WG

**ICRC-2: Recurring payments**

* Dieter summarizes the discussions of the proposal so far
  * Levi's proposal is about handling each approval separately with independent expirations
  * Currently, approvals are subsumed additively and the whole approved amount gets the expiration date of the latest approval
  * The proposal has the following properties:
    * Somewhat higher complexity of implementation
    * Cleaner modeling of data
    * Require more storage
  * A discussion in Dfinity has come to the following conclusions:
    * If we go for this proposal, we may want to also have a starting time for the approvals
    * We would not want to have negative approvals
    * We need to be able to cancel approvals
* Levi
  * Negative approvals have been removed in the proposal already in his PR
  * New method to cancel approvals by the id
  * Allowance now returns all allowances and approvals between account and spender
* Roman
  * Tried to implement previous version; main problem were negative amounts; needs representation of u64 for token amount and the sign; pain to have this; would be in favour of removing negative approvals
    * Semantics of expirations: Levi's proposal is most natural thing to have; each approval is a separate entity independent of other approvals; most people would expect this semantics when using this API
    * If we also have starting points of validity, users can use this for recurring payments
* Levi agrees that having a starting date is a great way of realizing recurring approvals
  * Better to have this than an approval type for recurring approvals
* Dieter explains an issue related to memory consumption and DoS potential
  * Attackers can create a large number of approvals and then repeatedly make transfers that need to touch many of those, but fail; this would consume lots of computational resources; this is fixable by a limit on the number of approvals between two entities; the parameter and applicable fees to work need to be determined
  * Levi thinks this would be a great thing to do
  * Levi wonders whether we should set it globalls for all ledgers
  * Dieter suggests we could make a recommendation or require a minimum and leave the decision to a ledger; 100 approvals as a minimum may make sense practically
  * Roman mentions that when needing more approvals, one can work around it with subaccounts, so the limit should not be a limiting issue
* Dieter raises the point of **overall memory consumption**: Is the additional memory consumption a problem?
  * Mario thinks it is the same as everything else in the ledger as a fee is paid
    * Same as approving different principals; does not add any more problems in his opinion
* **Differences to ERC-20**: Is that an issue?
  * Levi thinks it's not an issue; IC contracts are different than those in the synchronous world
  * Dieter also thinks we should not take over the limiting things from the ERC-20 world that originally have arised from the limitations of the synchronous world and Ethereum specifically
* Ben: strong opinions from DeFi people: they strongly oppose going for the proposal; higher complexity; gains in functionality do not outweight the costs
  * How elegant the implementation is should bear no weight on which semantics we implement as we are doing a standard; the user perspective is important; this proposal makes it more difficult to use
  * Roman: Does not think there is significant increase of implementation complexity
  * Ben motivates the opposition as he thinks that the backend needs the id of approvals to use them and it is more complex for the backend than using the current semantics
  * Mario: there is no alternative approach for services; need to try to do transfer_from
  * Ben: Then nobody would be spending per approval id?
  * Levi: Yes, that's not even possible; when you make a transfer from, the ledger uses approvals starting with the ones expiring soonest, sorting in ascending order by expiry
  * No added complexity for backend canister to use the proposed mechanism
  * Proposed approach
    * Pros of proposal: extra functionality; feels more natural
    * Cons: more memory consumtion
  * Mario thinks that the current approach of changing expiration date of old approvals with new approvals is not what one wants to do
  * If there's no difference on the spender side
  * People think that current and proposed approach are equally doable in terms of formal modelling; model might be cleaner with the new proposal, however
  * Roman's main concern is that people would assume it works like the proposed approach; that's a problem if we implement the current approach
  * Timo: Thinks it's hard to say what is natural; the proposal may be more complicated for the user; if careful, can cover new use cases, but if you are not careful, you can mess up; need to carefully track what you have done
    * Roman: There will be an endpoint where you can query all approvals
    * Timo: Yes, but the response is more complicated than getting back a single approval
    * Roman: The proposal gives you exactly what you asked for: series of approvals as user defined them; feels more natural; original reason for using additive semantics was that multiple concurrent transactions don't interfere with each other; with the current semantics, they interfere with each other, in the proposed semantics they don't as they are independent
    * Timo: current approach is like a step function
  * Ben: Are we over engineering the system?
    * Roman: Removing expiration dates completely would be much simpler; if we have expiration dates, we should do them correctly
  * Dieter: 2 questions to answer: (1) Do we want to keep the expiration date? (2) If so, how to implement it?
    * Dan: What about approving something that should be valid only during a range of time?
    * Dieter: That's possible with the extension of the proposal: Approvals have a starting and ending time
      * This does not substantially increase implementation complexity
    * Dieter asks the group who is in favour of not having expiration date
    * Roman: we should ask the community through a forum post on what they think about having expiration dates
      * Roman or Dieter will take care of this
    * No one in this group raised their hands in favour of removing expiration dates
  * Timo asks for clarification on semantics of proposal if multiple approvals are open
    * Levi clarifies: [PR101](https://github.com/dfinity/ICRC-1/pull/101) explains it
      * Ledger takes all current available approvals (after start date if there is one, before expiration date if there is one)
      * Sorts approvals by expiring soonest to expiring latest
      * Sums up remaining allowances of those approvals, makes sure amount to be transferred is less than or equal to this sum
      * Goes through sorted allowances list and starts deducting transfer amount and fee until transfer is covered
  * Levi: Should ICRC-2 approve have its own fee? Separate from ICRC-1 transfer function, different fee
    * Roman: no strong opinion, from storage point of view there is no big difference, we charge the same
    * Mario: ideally, we may want a different fee per operation
    * Roman: implementers are free to decide the fee
    * Mario: indeed, it would be best to not have the fee in the standard
    * Roman: send message to ledger with fee proposal; if ledger does not agree, it sends an error with its fee requirements; 1 extra hop to talk to ledger
    * Ben: this should not be in the standard as the fee is optional; should be up to implementation to decide
    * Levi: yes, that's a decent way forward; we have the fee error
  * Levi: Any comments on allowances args; get back earliest approval id and list of approvals
    * Roman: if we limit number to, e.g., 100, we don't need paging for retrieval; main issue with large amount of approvals between two entities is computation; 100 approvals easily fit into max response size; could use paging mechanism for future proofness
    * Levi: id also needed for cancelling approvals by id
    * Outcome of discussion: we should cap number of approvals
  * Levi: Comments on cancelling approvals
    * Ben, Roman: if cancelled, would return approval not found error; otherwise we need to keep the information on all cancelled approvals
  * Roman: Let's draft a post in the forum to get feedback on the proposal; Roman or Dieter
    * Ask what people want, for example:
      * Abandon expiration dates?
      * Which semantics to have?
* We continue the discussion on this item in the next meeting

**Action items**
* Roman / Dieter making a forum post to ask the community what they prefer


## 2023-03-07
[Slide deck](https://docs.google.com/presentation/d/11QcNtl8QFNg2LL1BrahDU559Uy7LoSXXPGJz_vDxKTk/edit?usp=share_link), [recording](https://drive.google.com/file/d/1jpwUIQgkDl_M-IVdKLOBMzXfoPA8j6Ad/view?usp=share_link)

**Textual encoding format for ICRC-1 account addresses: Checksum**

* Dieter summarizes where the group stands with the discussion
  * We have a decision on the following way of encoding: `principal | "-" | checksum | "." subaccount` for non-default subaccounts; leading zeroes in subaccounts are truncated in the hexadecimal representation
  * The default subaccount `0` is encoded as just the principal: `princial`
  * Now the checksum algorithm and length is to be decided: In the last meeting CRC-32 and CRC-16 and truncated versions thereof were up as potential candidates for discussion
* **Algorithm and length**
  * In a discussion we agreed that the success rate of non-truncated and truncated CRC-16 or CRC-32 are very similar and that the difference is not substantial enought to drive a decision. However, the availability of libraries is important for implementors of the standard. Here, CRC-16 has fewer libraries and there are many different polynomials used. For CRC-32, there are more libraries and one polynomial is widely used, essentially like a quasi standard.
  * Regarding encoding, there is a dicussion whether to use hex encoding or base-32 encoding, where the latter is used for the principal.
  * Timo prefers hex encoding for the reason of better tooling support, e.g., on the console. He thinks that it blends in with the actual principal as nicely as base-32-encoding. Ben also prefers hex initially.
  * There was a discussion what fraction of bit flips, e.g., due to copy-paste errors, would go undetected. 0.2% could go through unnoticed.
  * Dieter summarizes the discussion so far: Considering the team's argument of library availability, CRC-16 seems to be not the very good idea. CRC-32 seems to have one widely used polynomial. That's probably the default used in all the command line tools if you don't specify anything specific now, which means this would hint towards using CRC-32. The question is, would we want the full CRC-32 or would we want to truncate it down and then accept the slightly higher chance of not detecting errors. Would we use base-16 or base-32 for encoding? Those are the open questions right now. AFAIK, the principal has full CRC-32 with base-32 encoding as checksum.
  * Timo clarifies that in the principal encoding, the checksum is prefixed to the principal in the binary representation and the resulting string is encoded using base-32 and then grouped in groups of five characters.
  * Timo prefers two-byte truncated CRC-32 encoded in hex.
  * 20-bit truncated CRC-32 was discussed, but found to be harder to parse.
  * Matthew thinks we should go for the full checksum.
  * Dieter notes that this would be 8 hex characters, which gets long.
  * Dieter writes down how the different discussed variants would look like. He finds the full CRC-32 checksum in hex gets a bit too long.
  * We also look at 5 and 6 hex character truncated variants of the CRC-32 checksum.
  * We have now 4, 5, or 6 characters on the table.
  * Roman prefers the full one, either full CRC-32 or full CRC-16 because it's easier to implement.
  * Dieter clarifies that CRC-16 was found to not be a good idea before Roman has joined the call.
  * **Full CRC-32 without truncation is found to be the most suitable choice** because of the availability of libraries and command line tools and a widely-used quasi-standard polynomial.
* **Checksum over characters or binary data**
  * There is a discussion whether the checkum should be computed over the encoded characters or the bytes, which resolved that **computing the checksum over the bytes is what we should do** as it is the natural way. This is also how it is done for the principal. Also, this is optimizes the processing for canisters over client-side generation.
* **Encoding**
  * There is a discussion by Timo on why hex could be better in terms of tooling, e.g., one could use the standard command line tools easily. But it was not found a strong argument by most members in the group. Also, he finds base-32 as used in the principal non-standard.
  * Roman prefers base-32 mostly for how it better blends in.
  * The discussions continue on what is the better representation and why. We agree to make a vote to come to rough consensus.
  * The result is that the vast majority prefers **base-32 encoding**. We have rough consensus.
* **Summary of decisions**
  * Non-truncated CRC-32 checkum computed over the byte representation of the inputs.
  * Checksum is encoded with base-32 and appended with a hypen (`-`) to the principal.
* Roman volunteers to finish the specification.

**ICRC-2: Recurring payments**

* Levi explains his idea for expiration semantics for approvals and motivates it with problems of the currently-standing design of new approvals changing current ones additively, but the expiration is always set based on the latest approval. This can lead to an undesired accumulation of approvals.
* Roman: Might make sense to keep each approval a separate entity with its own expiration date. Approvals than expire independently of each other. If you make a transfer, the older available approval could be used, for example.
* Levi: We can have an optional approval ID parameter on the `transfer_from` function. Either a specific approval id can be used or deducted from the earliest approvals.
  * Mario clarifies that if you then use an approval id, then the ledger only considers this approval.
* Levi would see no harm in adding an optional approval id field.
* Ben thinks the extra complication of this extension does not justify the extra functionality. Strongly against it.
* It is clarified that approvals are always charged a fee to prevent DoS attacks.
* Mario also thinks that this may make things unnecessarily complicated.
* Roman: The logic to handle the transfers becomes a bit more complicated because you might need to process multiple approvals in one go. But I think it's still worth it because the semantics of each approval is a separate thing and expired in its own time, much cleaner than what we have now. And it's not much harder to implement than the original solution. It requires a bit more space, I agree, but I think it's much cleaner. And it's also fair because you pay for each approval.
* Dieter triggers a discussion on what this semantics would mean for formal verifiability.
  * The conclusion is that it would be easier to formally verify because the representation is cleaner.
* Levi suggests he will prepare an example for two scenarios so that we can assess the implications thereof in terms of implementation, complexity, and usability.
Roman: By the way, just last note, when I implemented reference implementation, the current variant was actually much harder to implement than the one when you have separate expirations. Because basically, if you want to know what's the allowance right now, you go through all the blocks, you know the current time stamp, you count all the approvals that happened that are still available for this block, and you look at all the transfers that happened. Much easier to figure out than trying to replay the logic and connect blocks. Okay, which one extends which one is very complicated. From formal verification point of view, the separate approvals is much clearer.


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
  * CRC-32 seems fine, SHA is most secure one and is likely not required for this
  * CRC-32 is used for the checksum in the principal
  * CRC-32 is easy to implement
  * Is it safe to trim a CRC-32 checksum to fewer bits?
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
