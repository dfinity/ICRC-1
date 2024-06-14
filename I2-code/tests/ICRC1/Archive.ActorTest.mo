import Debug "mo:base/Debug";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Nat64 "mo:base/Nat64";
import Principal "mo:base/Principal";
import EC "mo:base/ExperimentalCycles";

import Archive "../../src/ICRC1/Canisters/Archive";
import T "../../src/ICRC1/Types";

import ActorSpec "../utils/ActorSpec";

module {
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

    func new_tx(i : Nat) : T.Transaction {
        {
            kind = "";
            mint = null;
            burn = null;
            transfer = null;
            index = i;
            timestamp = Nat64.fromNat(i);
        };
    };

    // [start, end)
    func txs_range(start : Nat, end : Nat) : [T.Transaction] {
        Array.tabulate(
            (end - start) : Nat,
            func(i : Nat) : T.Transaction {
                new_tx(start + i);
            },
        );
    };

    func new_txs(length : Nat) : [T.Transaction] {
        txs_range(0, length);
    };

    let TC = 1_000_000_000_000;
    let CREATE_CANISTER = 100_000_000_000;

    func create_canister_and_add_cycles(n : Float) {
        EC.add(
            CREATE_CANISTER + Int.abs(Float.toInt(n * 1_000_000_000_000)),
        );
    };

    public func test() : async ActorSpec.Group {
        describe(
            "Archive Canister",
            [
                it(
                    "append_transactions()",
                    do {
                        create_canister_and_add_cycles(0.1);
                        let archive = await Archive.Archive();

                        let txs = new_txs(500);

                        assertAllTrue([
                            (await archive.total_transactions()) == 0,
                            (await archive.append_transactions(txs)) == #ok(),
                            (await archive.total_transactions()) == 500,
                        ]);
                    },
                ),
                it(
                    "get_transaction()",
                    do {
                        create_canister_and_add_cycles(0.1);
                        let archive = await Archive.Archive();

                        let txs = new_txs(3555);

                        let res = await archive.append_transactions(txs);

                        assertAllTrue([
                            res == #ok(),
                            (await archive.total_transactions()) == 3555,
                            (await archive.get_transaction(0)) == ?new_tx(0),
                            (await archive.get_transaction(999)) == ?new_tx(999),
                            (await archive.get_transaction(1000)) == ?new_tx(1000),
                            (await archive.get_transaction(1234)) == ?new_tx(1234),
                            (await archive.get_transaction(2829)) == ?new_tx(2829),
                            (await archive.get_transaction(3554)) == ?new_tx(3554),
                            (await archive.get_transaction(3555)) == null,
                            (await archive.get_transaction(999999)) == null,
                        ]);
                    },
                ),
                it(
                    "get_transactions()",
                    do {

                        create_canister_and_add_cycles(0.1);
                        let archive = await Archive.Archive();

                        let txs = new_txs(5000);

                        let res = await archive.append_transactions(txs);

                        let tx_range = await archive.get_transactions({
                            start = 3251;
                            length = 2000;
                        });

                        assertAllTrue([
                            res == #ok(),
                            (await archive.total_transactions()) == 5000,
                            (await archive.get_transactions({ start = 0; length = 100 })).transactions == txs_range(0, 100),
                            (await archive.get_transactions({ start = 225; length = 100 })).transactions == txs_range(225, 325),
                            (await archive.get_transactions({ start = 225; length = 1200 })).transactions == txs_range(225, 1425),
                            (await archive.get_transactions({ start = 980; length = 100 })).transactions == txs_range(980, 1080),
                            (await archive.get_transactions({ start = 3251; length = 2000 })).transactions == txs_range(3251, 5000),
                        ]);
                    },
                ),
            ],
        );
    };
};
