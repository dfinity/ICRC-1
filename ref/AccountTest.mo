import Account   "mo:account/Account";
import Array     "mo:base/Array";
import Blob      "mo:base/Blob";
import Debug     "mo:base/Debug";
import Nat8      "mo:base/Nat8";
import Principal "mo:base/Principal";
import Prelude   "mo:base/Prelude";
import Result    "mo:base/Result";
import Text      "mo:base/Text";
import Iter      "mo:base/Iter";

func hexDigit(b : Nat8) : Nat8 {
    switch (b) {
        case (48 or 49 or 50 or 51 or 52 or 53 or 54 or 55 or 56 or 57) { b - 48 };
        case (65 or 66 or 67 or 68 or 69 or 70) { 10 + (b - 65) };
        case (97 or 98 or 99 or 100 or 101 or 102) { 10 + (b - 97) };
        case _ { Prelude.nyi() };
    }
};

func hexDecode(t : Text) : Blob {
    assert (t.size() % 2 == 0);
    let n = t.size() / 2;
    let h = Blob.toArray(Text.encodeUtf8(t));
    var b : [var Nat8] = Array.init(n, Nat8.fromNat(0));
    for (i in Iter.range(0, n - 1)) {
        b[i] := hexDigit(h[2 * i]) << 4 | hexDigit(h[2 * i + 1]);
    };
    Blob.fromArrayMut(b)
};

func hexToPrincipal(hex : Text) : Text {
  Principal.toText(Principal.fromBlob(hexDecode(hex)))
};

func checkDecode(text : Text, expected : Result.Result<Account.Account, Account.DecodeError>) {
    let result = Account.fromText(text);
    if (result != expected) {
        Debug.print("expected text " # text # " to decode as " # debug_show expected # ", got: " # debug_show result);
    };
    assert(result == expected);
};

func checkEncode(acc : Account.Account, expected : Text) {
    let actual = Account.toText(acc);
    if (actual != expected) {
        Debug.print("expected account " # debug_show acc # " to be encoded as " # expected # ", got: " # actual);
    };
    assert(actual == expected);
};

checkEncode({ owner = Principal.fromText("aaaaa-aa"); subaccount = null }, "aaaaa-aa");
checkEncode({ owner = Principal.fromText("aaaaa-aa"); subaccount = ?hexDecode("0000000000000000000000000000000000000000000000000000000000000000") }, "aaaaa-aa");
checkEncode({ owner = Principal.fromText("2vxsx-fae"); subaccount = null }, "2vxsx-fae");
checkEncode({ owner = Principal.fromText("2vxsx-fae"); subaccount = ?hexDecode("0000000000000000000000000000000000000000000000000000000000000000") }, "2vxsx-fae");
checkEncode({ owner = Principal.fromText("2vxsx-fae"); subaccount = ?hexDecode("0000000000000000000000000000000000000000000000000000000000000001") }, hexToPrincipal("0401017f"));
checkEncode({ owner = Principal.fromText("2vxsx-fae"); subaccount = ?hexDecode("00000000000000000000ffffffffffffffffffffffffffffffffffffffffffff") }, hexToPrincipal("04ffffffffffffffffffffffffffffffffffffffffffff167f"));

checkDecode(hexToPrincipal(""), #ok({ owner = Principal.fromText("aaaaa-aa"); subaccount = null }));
checkDecode(hexToPrincipal("04"), #ok({ owner = Principal.fromText("2vxsx-fae"); subaccount = null }));
checkDecode(hexToPrincipal("7f"), #err(#bad_length));
checkDecode(hexToPrincipal("007f"), #err(#not_canonical));
checkDecode(hexToPrincipal("0401017f"), #ok({ owner = Principal.fromText("2vxsx-fae"); subaccount = ?hexDecode("0000000000000000000000000000000000000000000000000000000000000001") }));
checkDecode(hexToPrincipal("0401027f"), #ok({ owner = Principal.fromText("aaaaa-aa"); subaccount = ?hexDecode("0000000000000000000000000000000000000000000000000000000000000401") }));
checkDecode(hexToPrincipal("0401037f"), #err(#bad_length));
checkDecode(hexToPrincipal("0400017f"), #err(#not_canonical));
checkDecode(hexToPrincipal("040101010101010101010101010101010101010101010101010101010101010101207f"), #ok({ owner = Principal.fromText("2vxsx-fae"); subaccount = ?hexDecode("0101010101010101010101010101010101010101010101010101010101010101") }));