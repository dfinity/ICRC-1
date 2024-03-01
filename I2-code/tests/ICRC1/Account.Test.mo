import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";

import Itertools "mo:itertools/Iter";

import Account "../../src/ICRC1/Account";
import ActorSpec "../utils/ActorSpec";
import Archive "../../src/ICRC1/Canisters/Archive";

let {
    assertTrue;
    assertFalse;
    assertAllTrue;
    describe;
    it;
    skip;
    pending;
    run;
} = ActorSpec;

let principal = Principal.fromText("prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae");

let success = run([
    describe(
        "Account",
        [
            describe(
                "encode / decode Account",
                [
                    it(
                        "'null' subaccount",
                        do {
                            let account = {
                                owner = principal;
                                subaccount = null;
                            };

                            let encoded = Account.encode(account);
                            let decoded = Account.decode(encoded);
                            assertAllTrue([
                                encoded == Principal.toBlob(account.owner),
                                decoded == ?account,
                                Account.fromText("prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae") == ?account,
                                Account.toText(account) == "prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae",
                                Account.validate(account)
                            ]);
                        },
                    ),
                    it(
                        "subaccount with only zero bytes",
                        do {
                            let account = {
                                owner = principal;
                                subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]);
                            };

                            let encoded = Account.encode(account);
                            let decoded = Account.decode(encoded);

                            assertAllTrue([
                                encoded == Principal.toBlob(account.owner),
                                decoded == ?{ account with subaccount = null },
                                Account.fromText("prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae") == ?{ account with subaccount = null },
                                Account.toText(account) == "prb4z-5pc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae",
                                Account.validate(account)
                            ]);
                        },
                    ),
                    it(
                        "subaccount prefixed with zero bytes",
                        do {
                            let account = {
                                owner = principal;
                                subaccount = ?Blob.fromArray([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]);
                            };

                            let encoded = Account.encode(account);
                            let decoded = Account.decode(encoded);

                            let pricipal_iter = Principal.toBlob(account.owner).vals();

                            let valid_bytes : [Nat8] = [1, 2, 3, 4, 5, 6, 7, 8];
                            let suffix_bytes : [Nat8] = [
                                8, // size of valid_bytes
                                0x7f // ending tag
                            ];

                            let iter = Itertools.chain(
                                pricipal_iter,
                                Itertools.chain(
                                    valid_bytes.vals(),
                                    suffix_bytes.vals(),
                                ),
                            );

                            let expected_blob = Blob.fromArray(Iter.toArray(iter));

                            assertAllTrue([
                                encoded == expected_blob,
                                decoded == ?account,
                                Account.fromText("hamcw-wpc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iaeai-camca-kbqhb-aeh6") == ?account,
                                Account.toText(account) == "hamcw-wpc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iaeai-camca-kbqhb-aeh6",
                                Account.validate(account)
                            ]);
                        },
                    ),
                    it(
                        "subaccount with zero bytes surrounded by non zero bytes",
                        do {
                            let account = {
                                owner = principal;
                                subaccount = ?Blob.fromArray([1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8]);
                            };

                            let encoded = Account.encode(account);
                            let decoded = Account.decode(encoded);

                            let pricipal_iter = Principal.toBlob(account.owner).vals();

                            let valid_bytes : [Nat8] = [1, 2, 3, 4, 5, 6, 7, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 5, 6, 7, 8];
                            let suffix_bytes : [Nat8] = [
                                32, // size of valid_bytes
                                0x7f // ending tag
                            ];

                            let iter = Itertools.chain(
                                pricipal_iter,
                                Itertools.chain(
                                    valid_bytes.vals(),
                                    suffix_bytes.vals(),
                                ),
                            );

                            let expected_blob = Blob.fromArray(Iter.toArray(iter));

                            assertAllTrue([
                                encoded == expected_blob,
                                decoded == ?account,
                                Account.fromText("ojuko-dhc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iaeai-camca-kbqhb-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aacaq-daqcq-mbyie-b7q") == ?account,
                                Account.toText(account) == "ojuko-dhc7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iaeai-camca-kbqhb-aaaaa-aaaaa-aaaaa-aaaaa-aaaaa-aacaq-daqcq-mbyie-b7q",
                                Account.validate(account)
                            ]);
                        },
                    ),
                    it(
                        "subaccount with non zero bytes",
                        do {
                            let account = {
                                owner = principal;
                                subaccount = ?Blob.fromArray([123, 234, 156, 89, 92, 91, 42, 8, 15, 2, 20, 80, 60, 20, 30, 10, 78, 2, 3, 78, 89, 23, 52, 55, 1, 2, 3, 4, 5, 6, 7, 8]);
                            };

                            let encoded = Account.encode(account);
                            let decoded = Account.decode(encoded);

                            let pricipal_iter = Principal.toBlob(account.owner).vals();

                            let valid_bytes : [Nat8] = [123, 234, 156, 89, 92, 91, 42, 8, 15, 2, 20, 80, 60, 20, 30, 10, 78, 2, 3, 78, 89, 23, 52, 55, 1, 2, 3, 4, 5, 6, 7, 8];
                            let suffix_bytes : [Nat8] = [
                                32, // size of valid_bytes
                                0x7f // ending tag
                            ];

                            let iter = Itertools.chain(
                                pricipal_iter,
                                Itertools.chain(
                                    valid_bytes.vals(),
                                    suffix_bytes.vals(),
                                ),
                            );

                            let expected_blob = Blob.fromArray(Iter.toArray(iter));

                            assertAllTrue([
                                encoded == expected_blob,
                                decoded == ?account,
                                Account.fromText("tx2rl-b7c7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae67-ktrmv-ywzkb-ahqef-cqhqk-b4cso-aibu4-wixgq-3qcaq-daqcq-mbyie-b7q") == ?account,
                                Account.toText(account) == "tx2rl-b7c7u-zdfqi-cgv7o-fdyqf-n6afm-xh6hz-v4bk4-kpg3y-rvgxf-iae67-ktrmv-ywzkb-ahqef-cqhqk-b4cso-aibu4-wixgq-3qcaq-daqcq-mbyie-b7q",
                                Account.validate(account)
                            ]);
                        },
                    ),
                    it(
                        "should return false for invalid subaccount (length < 32)",
                        do {

                            var len = 0;
                            var is_valid = false;

                            label _loop while (len < 32){
                                let account = {
                                    owner = principal;
                                    subaccount = ?Blob.fromArray(Array.tabulate(len, Nat8.fromNat));
                                };

                                is_valid := is_valid or Account.validate(account) 
                                            or Account.validate_subaccount(account.subaccount);

                                if (is_valid) {
                                    break _loop;
                                };

                                len += 1;
                            };
                            
                            not is_valid;
                        }
                    )
                ],
            ),
        ],
    ),
]);

if (success == false) {
    Debug.trap("\1b[46;41mTests failed\1b[0m");
} else {
    Debug.print("\1b[23;42;3m Success!\1b[0m");
};
