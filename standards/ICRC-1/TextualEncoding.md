# Textual encoding of ICRC-1 accounts

This document specifies the canonical textual representation of ICRC-1 accounts.

ICRC-1 accounts have two components: the owner (up to 29 bytes) and the subaccount (32 bytes).
If the subaccount is not present, it's considered to be equal to an array with 32 zero bytes.

```candid
type Account = { owner : principal; subaccount : opt blob };
```

# Default accounts

The textual representation of the account coincides with the textual encoding of the account owner's principal if the `subaccount` is not set or equal to an array with 32 zero bytes.

```
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae";
    subaccount = null;
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae"
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
    subaccount = opt vec {0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0};
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae"
```

# Non-default accounts

The textual representation of accounts with non-default subaccounts consists of the following parts:
  1. The textual encoding of the owner's principal as described in the [Internet Computer Interface Specification](https://internetcomputer.org/docs/current/references/ic-interface-spec#textual-ids).
  2. A dash ('-') separating the principal from the checksum.
  3. The CRC-32 checksum of concatenated bytes of the principal (up to 29 bytes) and the subaccount (32 bytes).
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

In the following example, `dfxgiyy` is the checksum and `102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20` is the hex representation of the subaccount.

```
Account.toText(record {
    owner = principal "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
    subaccount = opt vec {1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20;21;22;23;24;25;26;27;28;29;30;31;32};
}) = "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-dfxgiyy.102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20"
```