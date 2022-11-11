# Internet Computer Working Group Operation and Governance

|   Status  |
|:---------:|
|   Draft   |

## Introduction

The work on the Internet Computer blockchain is a major joint effort by both the IC community and the DFINITY Foundation. The longer-term goal is to ever increase the involvement of the community in developing the Internet Computer technology in the future. A strong community involvement is crucial for multiple reasons, e.g., to address the requirements of a broad selection of IC stakeholders, particularly the active community members, and to have an increasingly decentralized approach to technology development.

The Internet Computer being a truly global project, the IC's stakeholders are distributed throughout the globe. This requires the collaboration to be virtual, to span all time zones, and to still be effective in terms of jointly developing standards and finding agreements. A crucial part of the technology development will take place in technical working groups (TWGs), typically involving stakeholders from both the wider community and DFINITY.

This document proposes an approach to the governance of and collaboration in Internet Computer (technical) working groups. The proposal provides a blueprint for how technical working groups can be set up and operate in terms of developing solutions that fulfill the stakeholders' needs as well as allow for finding agreement so that the stakeholders' interests can be aligned at large. The approach is applicable to any WG in the IC community, but at first is targeted at the Ledger and Tokenization working group, from which it has originated.

The proposed approach of IC WGs has borrowed some of its core ideas from the Internet Engineering Task Force (IETF). The IETF comprises, similar to the IC's WGs, volunteers that help drive the technology forward. IETF working groups, at the core of their working and decision making, use an informal approach based on *rough consensus* which attempts to find as-wide-as-possible consensus among the stakeholders in a working group. In a nutshell, rough consensus means that most of the eligible people are in agreement on an issue and remaining objections have been discussed and motivated why they have not been accommodated. The people not in consensus are "in the rough" part of consensus.

Due to the similarities between IETF and the IC community in terms of being volunteer communities that want to jointly develop great technology that moves the world forward, we conjecture that rough consensus can work equally well for the IC's working groups.

We next give more details on how working groups are structured in terms of members, the communication and collaboration approach and tooling used, and the consensus finding and decision making.

## Composition of a WG

An IC technical working group can be joined by anyone interested in participating in the discussions and joint development of the technology the WG addresses or just following the discussions. A subset of the members of the WG, the *core WG team members* will be most actively involved in the work, the remaining *participating members* will rather listen to discussions and occasionally make contributions.

* *Core WG team members:* The core team of the WG actively participates in the work of the WG and in developing the corresponding technology. The core team needs to be in agreement on the technical issues. The core team attempts to reach *rough consensus* as explained below and is eligible to vote in the WG, such as new standard proposals.
* *Participating members:* Anyone besides the core team is a *participating member* of the WG and can join the meetings and discussions on all channels. Participating members may express their opinions and are welcome to contribute to the work, however, they are not part of the decision making of the WG.
* *Chair:* Each WG appoints at least one chair, ideally two co-chairs, who are responsible for driving the WG, scheduling meetings, and orchestrating the processes of the WG. The chair is also responsible for determining whether the group is in rough consensus on a topic.

Finding the core team of a new WG to be established is an informal process that will quickly converge to an initial core team. The founding members or proposers of the WG will typically be part of the core team, quickly attracting further interested community members early on who are willing to contribute. The core team will evolve over time with members joining (or leaving), as the working group progresses.

The co-chairs of the WG should be agreed on by the WG in the spirit of WG decision making.

## Collaboration and communication

As the team members are distributed globally throughout all time zones and there are typically no physical face-to-face meetings of the WG, the methodology for collaboration needs to fully embrace an approach for efficient and effective virtual collaboration. IC WGs use multiple, but a small number of, communication channels and tools to collaborate. Both synchronous and asynchronous collaboration should be facilitated to allow for efficient progress of the technical work, resolving comments and objections by members, and converging to a broadly-accepted view among the core members, ultimately achieving rough consensus on an item.

For a distributed group like the IC community it is crucial to have a WG setup that can include also the people in the discussion that cannot attend the regular virtual WG meetings, e.g., due to time zone constraints.

IC WGs will typically use the collaboration tools mentioned below. The idea is to have as few tools as possible to avoid overhead for members (and the chairs).
* *GitHub* as asynchronous collaboration tool: working on documents and code; discussions on PRs; commenting on and objecting to specific issues of proposals; determining rough consensus through humming; formal voting
* *Virtual meetings in Zoom* as synchronous collaboration tool: technical discussions, continuing discussions from GitHub in a synchronous setting; discussion of strategic topics such as new work items, spawning a new working group; resolving issues
* *IC developer forum* as asynchronous communication channel: updates to the working group; announcements; technical discussions that do not fit into specific items on GitHub; strategic discussions

### GitHub

GitHub is the main tool for asynchronous collaboration in the WG, used for the following purposes, for example:

* Drafting standards proposals;
* Working on source code;
* Commenting on and objecting to (parts of) proposals;
* Technical discussions to address comments and objections;
* Asynchronous virtual humming;
* Voting.

### Virtual meetings in Zoom

Regular (typically weekly or bi-weekly 1-hour) virtual video conference meetings provide a platform for *synchronous collaboration* of the team. These meetings are the periodic integration points of discussions held on other channels, where team members can engage in a realtime discourse on the currently handled topics of the WG. The meeting cadence and schedule can be changed at the discretion of the WG, e.g., to align with the current workload or timeline requirements.

Particularly, the meetings are used, among other things, for the following:

* Discussing individual items the group is currently working on: A main part of the meetings is dedicated to addressing comments and objections on standards proposals in the spirit of rough consensus. This continues discussions on GitHub and uses the power of synchronous interactions between the participants.
* Elaborating the strategic roadmap of the WG: For example, discussing the direction, future work items, new WGs to be created for specific topics.
* Discussing upcoming work items.
* Virtual humming to assess the degree of consensus in the group.

WG meetings should have minutes published on GitHub that summarize the discussions and main decisions taken in the meeting. This helps transparency as well as participants who cannot participate in a meeting to catch up with the progress of the WG.

Due to the IC community's global presence, at least one of the geographies may not be conveniently able to participate during a given time slot. The WG can either choose a fixed time slot and involve the team members from non-participating geographies via other channels, or rotate the time slot so that all parts of the world can participate in a subset of the meetings. The further leads to a more stable attendance while being less fair towards one part of the team, the latter leads to a less stable participation of members while being fair. The chosen mode must be determined and decided by the WG.
Zoom meetings can be used for realtime humming during the meeting to measure rough consensus in the core team.

### Forum

Each WG has its own forum topic used for announcements and discussions. Announcements such as changes to the WG meeting schedule or upcoming asynchronous hums or votes are posted on the forum. Discussions that do not fit into a PR on GitHub also find their place on the forum. Technical discussions related to a specific topic should be done as part of the respective PR on GitHub, though. Any other communication not related to an item on GitHub can be done on the forum.

## Consensus and decision making

### Rough consensus

Building on ideas used in the IETF, the WG uses *rough consensus* as its main principle to reach agreement. It is highly recommended to read the [RFC](https://www.rfc-editor.org/rfc/rfc7282) by Pete Resnick on rough consensus to fully grasp the idea behind it. We give a brief overview here, do not go into much detail, but rather try to give the basic intuition.

Rough consensus means that the WG attempts to reach consensus among most of the WG members, but not necessarily all of them, as the latter would not be realistic in practice. Reaching rough consensus requires a methodology of collaboration where all reasonable objections of group members are addressed through thorough technical discussions or arguments and there is agreement at large on specifications after addressing objections.

Objections can either be accommodated, i.e., reflected through a change of the specification being discussed, or found to not be worth a change in the specification being made for good reasons. It is crucial that the reasoning in the latter case be technically sound. A not accommodated objection handled like this can make the objector be in consensus, even though it is not their preferred solution, but it is understood and accepted why it has not been accommodated. So they can live with it after the objection has been thoroughly addressed in a discussion, although it is not the perfect solution for them. If the objector thinks that the objection still remains valid after being discussed but not being accommodated, the objector is "in the rough" part of consensus, i.e., they still object, but their objections are not accommodated for given reasons.

The above means that the lack of disagreement is more important than the presence of agreement. If someone objecting can, after a thorough discussion, see that it does not make sense to accommodate the objection in the specification, they can live with the current specification, even if not perfect for them, and are in the consensus part, not in the rough part. If they still object, they are "in the rough" part of consensus.

Rough consensus is effective in reaching good outcomes – actually much better than a typical majority-based approach where often times "foul" compromises are made to get a majority, which may lead to bloated specifications with many effectively unaddressed issues. This is exactly not what rough consensus is about.

In larger groups it is likely that one or a few members are in the rough part of consensus and will remain there, i.e., have remaining objections after them being addressed, but not accommodated. Considering also that there may be members objecting for various non-technical reasons, the "rough" part of rough consensus is essential as unanimity would not work in practice.

### Determining rough consensus

In order to determine whether a group is in rough consensus, the WG can use the method of ["humming"](https://www.rfc-editor.org/rfc/rfc7282) as practiced by the IETF. Humming is a means of getting an informal assessment of the consensus on a given proposal, e.g., before initiating a vote. In many ways, humming is an informal poll of the group on a topic. The IC WGs need to revert to a "virtual humming" approach due to the group being fully remote and spread over the world, which may have different properties than the original IETF humming.

It is expected that, in the courtesy of good collaboration, members who accept a proposal in a hum do not object the same proposal in a vote. Different behaviour would not be in line with the ideas of the rough consensus approach. A WG may use any other means than virtual humming to get a sense of whether the group is in rough consensus. Humming does have the particular advantage that for many people it is easier to express a concern with a thumbs up or down emoji and comment in GitHub than it is by actively speaking up in the group. Also, virtual hums allow for including participants that cannot reasonably take part in the meetings because of their time zone. Thus, humming before initiating a vote will allow for getting a better picture of whether the WG is in rough consensus already or whether further discussion is required for a proposal to make it more mature. Particularly, humming can act as a request for comments and objections on a proposal and result in further input and discussions.

Technically, there are different viable options to implement a virtual hum to assess the consensus of the group:

* Thumbs up or down on a GitHub comment on the PR being discussed;
* Poll in an OpenChat group;
* Any other suitable tool that is simple to administrate and use and allows for sufficient access control.

This document proposes that asynchronous virtual humming be done by opening a *hum comment* in GitHub on the PR in question and posting a link to the hum on the forum. Members then have 2 days to post their opinions by a thumbs up or down emoji to express their opinion on the PR. Additionally, they can post comments or objections as response to the hum, which helps to come closer to rough consensus in the next iteration by doing another iteration on the specification. Multiple such hums may be required during the development of a standard proposal, which is well supported with this approach. Also, this results in a nice linear comment history on the PR.

Hums using GitHub are asynchronous, but have a rather high latency. Synchronous humming can be done using Zoom to get immediate feedback on the state of rough consensus.

It is at the discretion of the WG to adopt the approach of humming for sensing whether the group is in rough consensus or whether additional work needs to be done. Any other suitable mechanism can be used as alternative tool to achieve this.

### Voting

Once the WG has established rough consensus on a proposal, i.e., through its discussions over time on the subject and possibly supported by a (virtual) hum, the proposal can be subjected to a formal "vote" by the core WG members. Voting is initiated and closed by the chair of the WG. Voting in the WG requires a participation of at least 50% of the core WG members. A majority of two thirds is required for the acceptance of a proposal. Requiring a super majority for accepting a proposal is in-line with how major technical standards bodies handle voting. Still allowing for a fraction of members objecting in a vote may be necessary to be able to reach agreement for certain proposals, particularly for those on more controversial topics.

For the, hopefully unlikely, case of a WG not being able to achieve rough consensus on an issue and not getting agreement in a vote held despite impossibility of achieving rough consensus, a mechanism should be in place that helps resolve such situations. Details of this need to be refined further. One option would be that the WG can revert to an NNS vote to help resolve the issue, e.g., in the form of a consultative input or a decision on the crucial points that cannot be resolved. However, such situations are to be avoided in the light of the rough consensus approach.

Proposals accepted through a vote by the WG with a two-thirds super majority are moved forward to a formal vote by the NNS, following the usual principles of IC governance, on adoption of the proposal for the Internet Computer and its ecosystem.

## Conclusions

This document proposes how IC WGs can be governed. It has emerged from the Ledger and Tokenization WG due to a need for this group's own governance. As next steps, the proposal needs to be agreed upon as a starting point, of course using rough consensus, and then applied in the daily TWG practice and further refined as needed, first within the Ledger and Tokenization WG. The gained experience will lead to an iterative refinement and improvement. Other IC WGs are free to pick up this proposal or parts of it for their own governance and are invited to contribute to improving this proposal. Ideally, the IC community can converge to a single approach for how WGs operate and are governed to avoid every group having to reinvent the wheel.
