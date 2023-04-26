import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Text "mo:base/Text";

import Account "./Account";

func hexDigit(b : Nat8) : Nat8 {
  switch (b) {
    case (48 or 49 or 50 or 51 or 52 or 53 or 54 or 55 or 56 or 57) { b - 48 };
    case (65 or 66 or 67 or 68 or 69 or 70) { 10 + (b - 65) };
    case (97 or 98 or 99 or 100 or 101 or 102) { 10 + (b - 97) };
    case _ { Prelude.nyi() };
  };
};

func decodeHex(t : Text) : Blob {
  assert (t.size() % 2 == 0);
  let n = t.size() / 2;
  let h = Blob.toArray(Text.encodeUtf8(t));
  var b : [var Nat8] = Array.init(n, Nat8.fromNat(0));
  for (i in Iter.range(0, n - 1)) {
    b[i] := hexDigit(h[2 * i]) << 4 | hexDigit(h[2 * i + 1]);
  };
  Blob.fromArrayMut(b);
};

func checkEncode(principalText : Text, subaccount : ?[Nat8], expected : Text) {
  let principal = Principal.fromText(principalText);
  let encoded = Account.toText({
    owner = principal;
    subaccount = Option.map(subaccount, Blob.fromArray);
  });
  if (encoded != expected) {
    Debug.print("Expected: " # expected # "\nActual:   " # encoded);
    assert false;
  };
};

checkEncode(
  "iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae",
  null,
  "iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae",
);

checkEncode(
  "iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae",
  ?[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
  "iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae",
);

checkEncode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
  ?[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32],
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-dfxgiyy.102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20",
);

checkEncode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae",
  ?[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627i.1",
);

func checkDecode(input : Text, expected : Result.Result<Account.Account, Account.ParseError>) {
  let account = Account.fromText(input);
  if (account != expected) {
    Debug.print("Expected: " # debug_show expected # "\nActual:   " # debug_show account);
    assert false;
  };
};

func defAccount(owner : Text) : Account.Account {
  { owner = Principal.fromText(owner); subaccount = null };
};

func account(owner : Text, subaccount : [Nat8]) : Account.Account {
  {
    owner = Principal.fromText(owner);
    subaccount = ?Blob.fromArray(subaccount);
  };
};

checkDecode(
  "iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae",
  #ok(defAccount("iooej-vlrze-c5tme-tn7qt-vqe7z-7bsj5-ebxlc-hlzgs-lueo3-3yast-pae")),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-dfxgiyy.102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20",
  #ok(
    account("k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])
  ),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627i.1",
  #ok(
    account("k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae", [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1])
  ),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627i.01",
  #err(#not_canonical),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae.1",
  #err(#bad_checksum),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-6cc627j.1",
  #err(#bad_checksum),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-7cc627i.1",
  #err(#bad_checksum),
);

checkDecode(
  "k2t6j-2nvnp-4zjm3-25dtz-6xhaa-c7boj-5gayf-oj3xs-i43lp-teztq-6ae-q6bn32y.",
  #err(#not_canonical),
);
