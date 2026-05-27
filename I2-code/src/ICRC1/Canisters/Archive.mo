import Prim "mo:prim";

import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Hash "mo:base/Hash";
import Result "mo:base/Result";

import ExperimentalCycles "mo:base/ExperimentalCycles";
import ExperimentalStableMemory "mo:base/ExperimentalStableMemory";

import Itertools "mo:itertools/Iter";
import StableTrieMap "mo:StableTrieMap";
import U "../Utils";
import T "../Types";

shared ({ caller = ledger_canister_id }) actor class Archive() : async T.ArchiveInterface {

    type Transaction = T.Transaction;
    type MemoryBlock = {
        offset : Nat64;
        size : Nat;
    };

    stable let KiB = 1024;
    stable let GiB = KiB ** 3;
    stable let MEMORY_PER_PAGE : Nat64 = Nat64.fromNat(64 * KiB);
    stable let MIN_PAGES : Nat64 = 32; // 2MiB == 32 * 64KiB
    stable var PAGES_TO_GROW : Nat64 = 2048; // 64MiB
    stable let MAX_MEMORY = 32 * GiB;

    stable let BUCKET_SIZE = 1000;
    stable let MAX_TRANSACTIONS_PER_REQUEST = 5000;

    stable var memory_pages : Nat64 = ExperimentalStableMemory.size();
    stable var total_memory_used : Nat64 = 0;

    stable var filled_buckets = 0;
    stable var trailing_txs = 0;

    stable let txStore = StableTrieMap.new<Nat, [MemoryBlock]>();

    public shared ({ caller }) func append_transactions(txs : [Transaction]) : async Result.Result<(), Text> {

        if (caller != ledger_canister_id) {
            return #err("Unauthorized Access: Only the ledger canister can access this archive canister");
        };

        var txs_iter = txs.vals();

        if (trailing_txs > 0) {
            let last_bucket = StableTrieMap.get(
                txStore,
                Nat.equal,
                U.hash,
                filled_buckets,
            );

            switch (last_bucket) {
                case (?last_bucket) {
                    let new_bucket = Iter.toArray(
                        Itertools.take(
                            Itertools.chain(
                                last_bucket.vals(),
                                Iter.map(txs.vals(), store_tx),
                            ),
                            BUCKET_SIZE,
                        ),
                    );

                    if (new_bucket.size() == BUCKET_SIZE) {
                        let offset = (BUCKET_SIZE - last_bucket.size()) : Nat;

                        txs_iter := Itertools.fromArraySlice(txs, offset, txs.size());
                    } else {
                        txs_iter := Itertools.empty();
                    };

                    store_bucket(new_bucket);
                };
                case (_) {};
            };
        };

        for (chunk in Itertools.chunks(txs_iter, BUCKET_SIZE)) {
            store_bucket(Array.map(chunk, store_tx));
        };

        #ok();
    };

    func total_txs() : Nat {
        (filled_buckets * BUCKET_SIZE) + trailing_txs;
    };

    public shared query func total_transactions() : async Nat {
        total_txs();
    };

    public shared query func get_transaction(tx_index : T.TxIndex) : async ?Transaction {
        let bucket_key = tx_index / BUCKET_SIZE;

        let opt_bucket = StableTrieMap.get(
            txStore,
            Nat.equal,
            U.hash,
            bucket_key,
        );

        switch (opt_bucket) {
            case (?bucket) {
                let i = tx_index % BUCKET_SIZE;
                if (i < bucket.size()) {
                    ?get_tx(bucket[tx_index % BUCKET_SIZE]);
                } else {
                    null;
                };
            };
            case (_) {
                null;
            };
        };
    };

    public shared query func get_transactions(req : T.GetTransactionsRequest) : async T.TransactionRange {
        let { start; length } = req;
        var iter = Itertools.empty<MemoryBlock>();

        let end = start + length;
        let start_bucket = start / BUCKET_SIZE;
        let end_bucket = (Nat.min(end, total_txs()) / BUCKET_SIZE) + 1;

        label _loop for (i in Itertools.range(start_bucket, end_bucket)) {
            let opt_bucket = StableTrieMap.get(
                txStore,
                Nat.equal,
                U.hash,
                i,
            );

            switch (opt_bucket) {
                case (?bucket) {
                    if (i == start_bucket) {
                        iter := Itertools.fromArraySlice(bucket, start % BUCKET_SIZE, Nat.min(bucket.size(), end));
                    } else if (i + 1 == end_bucket) {
                        let bucket_iter = Itertools.fromArraySlice(bucket, 0, end % BUCKET_SIZE);
                        iter := Itertools.chain(iter, bucket_iter);
                    } else {
                        iter := Itertools.chain(iter, bucket.vals());
                    };
                };
                case (_) { break _loop };
            };
        };

        let transactions = Iter.toArray(
            Iter.map(
                Itertools.take(iter, MAX_TRANSACTIONS_PER_REQUEST),
                get_tx,
            ),
        );

        { transactions };
    };

    public shared query func remaining_capacity() : async Nat {
        MAX_MEMORY - Nat64.toNat(total_memory_used);
    };

    /// Deposit cycles into this archive canister.
    public shared func deposit_cycles() : async () {
        let amount = ExperimentalCycles.available();
        let accepted = ExperimentalCycles.accept(amount);
        assert (accepted == amount);
    };

    func to_blob(tx : Transaction) : Blob {
        to_candid (tx);
    };

    func from_blob(tx : Blob) : Transaction {
        switch (from_candid (tx) : ?Transaction) {
            case (?tx) tx;
            case (_) Debug.trap("Could not decode tx blob");
        };
    };

    func store_tx(tx : Transaction) : MemoryBlock {
        let blob = to_blob(tx);

        if ((memory_pages * MEMORY_PER_PAGE) - total_memory_used < (MIN_PAGES * MEMORY_PER_PAGE)) {
            ignore ExperimentalStableMemory.grow(PAGES_TO_GROW);
            memory_pages += PAGES_TO_GROW;
        };

        let offset = total_memory_used;

        ExperimentalStableMemory.storeBlob(
            offset,
            blob,
        );

        let mem_block = {
            offset;
            size = blob.size();
        };

        total_memory_used += Nat64.fromNat(blob.size());
        mem_block;
    };

    func get_tx({ offset; size } : MemoryBlock) : Transaction {
        let blob = ExperimentalStableMemory.loadBlob(offset, size);

        let tx = from_blob(blob);
    };

    func store_bucket(bucket : [MemoryBlock]) {

        StableTrieMap.put(
            txStore,
            Nat.equal,
            U.hash,
            filled_buckets,
            bucket,
        );

        if (bucket.size() == BUCKET_SIZE) {
            filled_buckets += 1;
            trailing_txs := 0;
        } else {
            trailing_txs := bucket.size();
        };
    };
};
