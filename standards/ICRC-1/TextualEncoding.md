# Textual encoding of ICRC-1 accounts

| Status |
|:------:|
| Accepted |

This document specifies the canonical textual representation of ICRC-1 accounts.

ICRC-1 accounts have two components: the owner (up to 29 bytes) and the subaccount (32 bytes).
If the subaccount is not present, it's considered to be equal to an array with 32 zero bytes.

```candid
type Account = { owner : principal; subaccount : opt blob };
```

## Default accounts

The textual representation of the account coincides with the textual encoding of the account owner's principal if the `subaccount` is not set or equal to an array with 32 zero bytes.

```
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae";
    subaccount = null;
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae"
```

```
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
    subaccount = opt vec {0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0};
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae"
```

## Non-default accounts

The textual representation of accounts with non-default subaccounts consists of the following parts:
  1. The textual encoding of the owner's principal as described in the [Internet Computer Interface Specification](https://internetcomputer.org/docs/current/references/ic-interface-spec#textual-ids).
  2. A dash ('-') separating the principal from the checksum.
  3. The CRC-32 checksum of concatenated bytes of the principal (up to 29 bytes) and the subaccount (32 bytes), encoded in [Base 32 encoding](https://datatracker.ietf.org/doc/html/rfc4648#section-6), without padding, and using lower-case letters.
  4. A period ('.') separating the checksum from the subaccount.
  5. The hex-encoded bytes of the subaccount with all the leading '0' characters removed.

```
<principal>-<checksum>.<compressed-subaccount>
```

```
Account.toText({ owner; ?subaccount }) = {
  let checksum = bigEndianBytes(crc32(concatBytes(Principal.toBytes(owner), subaccount)));
  Principal.toText(owner) # '-' # base32LowerCaseNoPadding(checksum) # '.' # trimLeading('0', hex(subaccount))
}
```

In the following example, `dfxgiyy` is the checksum and `102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20` is the hex representation of the subaccount with stripped leading zeros.

```
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
    subaccount = opt vec {1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32};
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-dfxgiyy.102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
```

## Examples

| Text | Result | Comment |
|:----:|:------:|:-------:|
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae` | OK: `{ owner = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae", subaccount = null }` | A valid principal is a valid account. |
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-q6bn32y.` | Error | The representation is not canonical: default subaccount should be omitted. |
| `k2t6j2nvnp4zjm3-25dtz6xhaac7boj5gayfoj3xs-i43lp-teztq-6ae` | Error | Invalid principal encoding. |
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627i.1` | OK: `{ owner = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae", subaccount = opt blob "\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\00\01" }` | |
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627i.01` | Error | The representation is not canonical: leading zeros are not allowed in subaccounts. |
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae.1` | Error | Missing check sum. |
| `k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-dfxgiyy.102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20` | OK: `{ owner = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae"; subaccount = opt blob "\01\02\03\04\05\06\07\08\09\0a\0b\0c\0d\0e\0f\10\11\12\13\14\15\16\17\18\19\1a\1b\1c\1d\1e\1f\20" }` | |

## Libraries

* [`ic-js`](https://github.com/dfinity/ic-js/tree/main/packages/ledger-icrc#gear-encodeicrcaccount) (JavaScript).
* [`icrc-ledger-types`](https://docs.rs/icrc-ledger-types/0.1.2/icrc_ledger_types/icrc1/account/struct.Account.html) version `0.1.2` and higher (Rust).
* [`icrc1`](https://github.com/NatLabs/icrc1) (Motoko)
