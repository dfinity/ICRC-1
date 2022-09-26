import Array     "mo:base/Array";
import Blob      "mo:base/Blob";
import Buffer    "mo:base/Buffer";
import Option    "mo:base/Option";
import Result    "mo:base/Result";
import Nat8      "mo:base/Nat8";
import Principal "mo:base/Principal";

module {
    public type Account = { owner : Principal; subaccount : ?Blob };
    public type DecodeError = {
        // Subaccount length is invalid.
        #bad_length;
        // The subaccount encoding is not canonical.
        #not_canonical;
    };

    public func toText(acc : Account) : Text {
        switch (acc.subaccount) {
            case (null) { Principal.toText(acc.owner) };
            case (?blob) {
                assert(blob.size() == 32);
                var zeroCount = 0;

                label l for (byte in blob.vals()) {
                    if (byte == 0) { zeroCount += 1; }
                    else break l;
                };

                if (zeroCount == 32) {
                    Principal.toText(acc.owner)
                } else {
                    let principalBytes = Principal.toBlob(acc.owner);
                    let buf = Buffer.Buffer<Nat8>(principalBytes.size() + blob.size() - zeroCount + 2);

                    for (b in principalBytes.vals()) {
                        buf.add(b);
                    };

                    var j = 0;
                    label l for (b in blob.vals()) {
                        j += 1;
                        if (j <= zeroCount) {
                            continue l;
                        };
                        buf.add(b);
                    };

                    buf.add(Nat8.fromNat(32 - zeroCount));
                    buf.add(Nat8.fromNat(0x7f));
                    
                    Principal.toText(Principal.fromBlob(Blob.fromArray(buf.toArray())))
                }
            }
        }
    };

    public func fromText(text : Text) : Result.Result<Account, DecodeError> {
        let principal = Principal.fromText(text);
        let bytes = Blob.toArray(Principal.toBlob(principal));

        if (bytes.size() == 0 or bytes[bytes.size() - 1] != Nat8.fromNat(0x7f)) {
            return #ok({ owner = principal; subaccount = null });
        };

        if (bytes.size() == 1) {
            return #err(#bad_length);
        };

        let n =  Nat8.toNat(bytes[bytes.size() - 2]);
        if (n == 0) {
            return #err(#not_canonical);
        };
        if (n > 32 or bytes.size() < n + 2 ) {
            return #err(#bad_length);
        };
        if (bytes[bytes.size() - n - 2] == Nat8.fromNat(0)) {
            return #err(#not_canonical);
        };

        let zeroCount = 32 - n;
        let subaccount = Blob.fromArray(Array.tabulate(32, func (i: Nat) : Nat8 {
            if (i < zeroCount) { Nat8.fromNat(0) }
            else { bytes[bytes.size() - n - 2 + i - zeroCount] }
        }));

        let owner = Blob.fromArray(Array.tabulate(bytes.size() - n - 2, func (i : Nat) : Nat8 { bytes[i] }));

        #ok({ owner = Principal.fromBlob(owner); subaccount = ?subaccount })
    }
}