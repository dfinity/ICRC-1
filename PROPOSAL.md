# The ICRC-1 Fungible Token Standard

## Introduction

​​The ICRC-1 Fungible Token Standard is the product of the collaborative effort of the [Ledger & Tokenization working group](https://forum.dfinity.org/t/announcing-token-standard-as-topic-of-the-first-meeting-of-the-ledger-tokenization-working-group/11925/1), including members from the [DFINITY Foundation](https://dfinity.org/), [InfinitySwap](https://infinityswap.one/), [Demergent Labs](https://github.com/demergent-labs), [ICDevs](https://icdevs.org/), [Tomahawk.vc](https://www.tomahawk.vc/), [Enoki](https://enoki.ooo/), [Distrikt](https://distrikt.app), LIFTECHNOLOGY, [Internet Identity Labs](https://nfid.one/), and the [ORIGYN Foundation](https://www.origyn.com/).
This proposal describes the core features of the proposed standard, its expected evolution, and arguments for and against the standard to help you make an informed decision.

## Motivation

On the 6th of March 2021, the ICP ledger [minted the first tokens](https://dashboard.internetcomputer.org/transaction/9e32c54975adf84a1d98f19df41bbc34a752a899c32cc9c0000200b2c4308f85).
Since then, the DeFi ecosystem has flourished:

* The [Psychedelic Studio](https://psychedelic.ooo/) built a rich ecosystem around the [DIP20](https://github.com/Psychedelic/DIP20) token standard.
* The [ORIGYN Foundation](https://www.origyn.com/) launched their [OGY](https://www.origyn.com/ogy) token powered by the ICP ledger technology.
* [InfinitySwap](https://infinityswap.one/) developed the [IS20](https://www.blog.infinityswap.one/infinityswap-the-is20-token-standard-decentralized-and-interoperable/) token standard.
* [ToniqLabs](https://toniqlabs.com/) developed the [EXT](https://github.com/Toniq-Labs/extendable-token) token standard.

The proliferation of token standards makes it hard for smart contract and tools developers to pick the foundation to build on.
In April 2022, many interested parties joined the Ledger & Tokenization working group to agree on a standard that could serve as a basic framework for token ledgers on the Internet Computer and improve the interoperability of DeFi services.

## What does the standard imply?

ICRC-1 is a contract between organizations participating in the Ledger & Tokenization working group and the community.
If the standard is accepted, we agree to

* Provide a production-ready implementation of the standard.
* Support the standard in our existing and future products.
* Build tools to interact with standard-compliant implementations.
* Promote the standard.
* Design extensions to the standard to simplify and scale payment flows.

Accepting the ICRC-1 standard does not imply that all other standards should be considered obsolete.
Everyone is free to experiment with new designs, application interfaces, and products.

The main goal of ICRC-1 is to provide a solid common ground for interoperability.

## Arguments for the standard

* This standard builds on lessons learned from operating and extending the ICP ledger, [one of the largest token ledgers](https://dashboard.internetcomputer.org/transactions) in the ecosystem.
* It is possible to integrate ICRC-1 endpoints into all major token ledger implementations, including the ICP ledger and most ledgers modeled after the [ERC-20](https://ethereum.org/en/developers/docs/standards/tokens/erc-20/) token standard (see the [Two-component account structure](#two-component-account-structure) subsection for more detail).
* The standard is known to have [a scalable and secure implementation](https://github.com/dfinity/ic/tree/1b2e15f17f8a2beaf28f802d675240f252585a30/rs/rosetta-api/icrc1) that will ship with the [SNS](https://medium.com/dfinity/how-the-service-nervous-system-sns-will-bring-tokenized-governance-to-on-chain-dapps-b74fb8364a5c).
* The standard has a modular design allowing future extensions without the loss of backward compatibility (see the [Modularity](#modularity) subsection).

## Comments on the arguments against this standard

The Ledger & Tokenization working group collected feedback from its members and the community. Below are the common arguments against accepting ICRC-1 as a standard and the commentary from the working group.

* **&ldquo;ICRC-1 does not provide a reasonable payment flow.&rdquo;**

  The standard is intentionally conservative and purposely avoids features that have known security flaws or can compromise the correctness or scalability of implementation with the current state of the core platform.
  Instead of cramming as much functionality as possible into a single API, the working group decided to include only the necessary and universal functionality into ICRC-1 and standardize additional payment flows as future extensions (see the [Modularity](#modularity) subsection).
  Note that the [proposed interface](#the-application-programming-interface) is powerful enough to support a payment flow based on subaccounts.
  All canisters smart contracts interacting with the ICP ledger rely on that flow.

* **&ldquo;ICRC-1 provides no benefits over alternatives.&rdquo;**

  ICRC-1 does not seek to replace existing standards but rather complement them, providing a unified interface for token transfers.
  Most token ledgers should be able to become standard-compliant without having to throw away their transaction logs.

* **&ldquo;It is too late to introduce a standard.&rdquo;**

  The core team is working on many features that can reshape DeFi on the Internet Computer.
  Some working group members think it is too early to agree on a single standard for all purposes!
  ICRC-1&rsquo;s extension mechanism allows the DeFi capabilities to grow as the platform evolves.
  See the [Modularity](#modularity) subsection for more detail.

* **&ldquo;The account addressing scheme involving subaccounts is unnecessarily complicated.&rdquo;**

  Subaccounts are a polarizing feature; however, most working group members found them valuable in practice, and most users have experience with subaccounts from traditional banking systems.
  See the [Two-component account structure](#two-component-account-structure) subsection for more detail.

## The application programming interface

Below is the entire [Candid](https://github.com/dfinity/candid) interface required by the standard.

```candid
type Timestamp = nat64; // UNIX timestamp, nanoseconds
type Subaccount = blob; // 32-byte blob
type Memo = blob;       // up to 32 bytes long

type Account = record { owner : principal; subaccount : opt Subaccount; };

type TransferArgs = record {
    from_subaccount : opt Subaccount;
    to : Account;
    amount : nat;
    fee : opt nat;
    memo : opt Memo;
    created_at_time : opt Timestamp;
};

type TransferError = variant {
    BadFee : record { expected_fee : nat };
    BadBurn : record { min_burn_amount : nat };
    InsufficientFunds : record { balance : nat };
    TooOld;
    CreatedInFuture: record { ledger_time : Timestamp };
    Duplicate : record { duplicate_of : nat };
    TemporarilyUnavailable;
    GenericError : record { error_code : nat; message : text };
};

type Value = variant { Nat : nat; Int : int; Text : text; Blob : blob; };

service : {
    icrc1_metadata : () -> (vec record { text; Value; }) query;
    icrc1_name : () -> (text) query;
    icrc1_symbol : () -> (text) query;
    icrc1_decimals : () -> (nat8) query;
    icrc1_fee : () -> (nat) query;
    icrc1_total_supply : () -> (nat) query;
    icrc1_minting_account : () -> (opt Account) query;
    icrc1_balance_of : (Account) -> (nat) query;
    icrc1_transfer : (TransferArgs) -> (variant { Ok : nat; Err : TransferError });
    icrc1_supported_standards : () -> (vec record { name : text; url : text }) query;
}
```

## Core traits of the standard

### Two-component account structure

ICRC-1 identifies [accounts](https://github.com/dfinity/ICRC-1#account) with a [principal](https://internetcomputer.org/docs/current/references/ic-interface-spec/#principal) and an optional subaccount.
A subaccount is an arbitrary 32-byte blob.
Below are the arguments against clumping the owner and the subaccount irreversibly on the interface level:

* Having address components unobscured is crucial for interoperability because it allows for more compliant implementations.
  For example, the ICP ledger can turn the address components into an [account identifier](https://internetcomputer.org/docs/current/references/ledger#_accounts), and ledgers using principals to identify accounts can use [derived principals](https://internetcomputer.org/docs/current/references/ic-interface-spec/#id-classes) instead.
  Enforcing a specific encoding would harm interoperability.
* The ability to pass account components unaltered removes the need to link complex account identifier computation libraries to each ledger client.
* Having owners and subaccounts in the transaction log enables new kinds of applications.
  For example, it becomes possible to build auxiliary smart contracts acting as replicators indexing the transaction log or sending out notifications (note, however, that the standard [does not specify how to access the transaction log](#unspecified-transaction-structure)).
* Implementations storing unaltered principals and subaccounts allow clients to recover their state fully by replaying records from the transaction log.
* Two-component structure maps well to the [Rosetta API specification of account identifiers](https://www.rosetta-api.org/docs/api_identifiers.html#account-identifier).

### Namespaces

All ICRC-1 [methods](https://github.com/dfinity/ICRC-1#methods) have the `icrc1_` prefix.
This feature allows existing smart contracts to implement ICRC-1 methods without introducing name clashes.

### Unspecified transaction structure

ICRC-1 _does not_ specify the structure of transactions or provide methods for fetching them.
That deliberate design choice enables backward compatibility with existing token ledgers, such as the ICP ledger.
The Ledger & Tokenization working group plans to work on an _optional_ extension specifying the interface for fetching transactions.


### Metadata access

ICRC-1 defines a [generic metadata mechanism](https://github.com/dfinity/ICRC-1#metadata) allowing ledger implementations to define application-specific attributes, such as token logos and URLs (see the [icrc1_metadata](https://github.com/dfinity/ICRC-1#icrc1_metadata-) method).


### Modularity

ICRC-1 is the _base_ standard designed for extension with follow-up specifications as new flows become practical.
Many efficient flows require unique features of the IC platform, such as [Threshold ECDSA signatures](https://medium.com/dfinity/threshold-ecdsa-the-key-ingredient-behind-the-internet-computers-bitcoin-and-ethereum-cf22649b98a1), to become stable and well-understood.
The standard defines the [icrc1_supported_standards](https://github.com/dfinity/ICRC-1#icrc1_supported_standards) method listing all standards the token ledger supports.
This method will allow applications such as wallets and Rosetta API implementations to discover and take advantage of additional features in the future.

The Ledger & Tokenization working group will continue working on a set of extensions recommended (but not required) for all ledger implementations.
Furthermore, anyone can define new extensions and include them into the supported standards list.
For example, existing [DIP20](https://github.com/Psychedelic/DIP20)-compatible ledgers can include DIP-20 into the supported standards list, allowing compatible clients to discover and access the corresponding API.


### Transaction deduplication semantics

ICRC-1 defines a [protocol for transaction deduplication](https://github.com/dfinity/ICRC-1#transaction-deduplication-) to help clients avoid accidental double spending in the presence of temporary networking issues without the need to implement complex recovery mechanisms.


## Interoperability of ICRC-1 and the ICP ledger

The DFINITY Foundation plans to implement the ICRC-1 interface in the ICP ledger canister smart contract.
Though ICRC-1 is compatible with the ICP ledger design, transferring funds to 28-byte ICP account identifiers will not be possible through the ICRC-1 interface.
You will have to use the existing ICP ledger interface for such transfers.


## Conclusion

The [Ledger & Tokenization working group](https://forum.dfinity.org/t/announcing-token-standard-as-topic-of-the-first-meeting-of-the-ledger-tokenization-working-group/11925/1) proposes to adopt the [ICRC-1](https://github.com/dfinity/ICRC-1) token standard as a common interface for transferring fungible tokens on the Internet Computer.
The standard does not seek to replace existing token ledgers but rather to serve as a base interface for accessing them.
The working group agrees to implement, integrate, and promote the standard and work on its extensions.
