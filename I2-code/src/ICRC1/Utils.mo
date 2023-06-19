import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

import ArrayModule "mo:array/Array";
import Itertools "mo:itertools/Iter";
import STMap "mo:StableTrieMap";
import StableBuffer "mo:StableBuffer/StableBuffer";

import Account "Account";
import T "Types";

module {
    // Creates a Stable Buffer with the default metadata and returns it.
    public func init_metadata(args : T.InitArgs) : StableBuffer.StableBuffer<T.MetaDatum> {
        let metadata = SB.initPresized<T.MetaDatum>(4);
        SB.add(metadata, ("icrc1:fee", #Nat(args.fee)));
        SB.add(metadata, ("icrc1:name", #Text(args.name)));
        SB.add(metadata, ("icrc1:symbol", #Text(args.symbol)));
        SB.add(metadata, ("icrc1:decimals", #Nat(Nat8.toNat(args.decimals))));

        metadata;
    };

    public let default_standard : T.SupportedStandard = {
        name = "ICRC-1";
        url = "https://github.com/dfinity/ICRC-1";
    };

    public let icrc2_standard : T.SupportedStandard = {
        name = "ICRC-2";
        url = "https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-2";
    };

    // Creates a Stable Buffer with the default supported standards and returns it.
    public func init_standards() : StableBuffer.StableBuffer<T.SupportedStandard> {
        let standards = SB.initPresized<T.SupportedStandard>(4);
        SB.add(standards, default_standard);
        SB.add(standards, icrc2_standard);
        standards;
    };

    // Returns the default subaccount for cases where a user does
    // not specify it.
    public func default_subaccount() : T.Subaccount {
        Blob.fromArray(
            Array.tabulate(32, func(_ : Nat) : Nat8 { 0 })
        );
    };

    // this is a local copy of deprecated Hash.hashNat8 (redefined to suppress the warning)
    func hashNat8(key : [Nat32]) : Hash.Hash {
        var hash : Nat32 = 0;
        for (natOfKey in key.vals()) {
            hash := hash +% natOfKey;
            hash := hash +% hash << 10;
            hash := hash ^ (hash >> 6);
        };
        hash := hash +% hash << 3;
        hash := hash ^ (hash >> 11);
        hash := hash +% hash << 15;
        return hash;
    };

    // Computes a hash from the least significant 32-bits of `n`, ignoring other bits.
    public func hash(n : Nat) : Hash.Hash {
        let j = Nat32.fromNat(n);
        hashNat8([
            j & (255 << 0),
            j & (255 << 8),
            j & (255 << 16),
            j & (255 << 24),
        ]);
    };

    // Formats the different operation arguements into
    // a `TransactionRequest`, an internal type to access fields easier.
    public func create_transfer_req(
        args : T.TransferArgs,
        owner : Principal,
        tx_kind : T.TxKind,
    ) : T.TransactionRequest {

        let from = {
            owner;
            subaccount = args.from_subaccount;
        };

        let encoded = {
            from = Account.encode(from);
            to = Account.encode(args.to);
        };

        switch (tx_kind) {
            case (#mint) {
                {
                    args with kind = #mint;
                    fee = null;
                    from;
                    encoded;
                };
            };
            case (#burn) {
                {
                    args with kind = #burn;
                    fee = null;
                    from;
                    encoded;
                };
            };
            case (#transfer) {
                {
                    args with kind = #transfer;
                    from;
                    encoded;
                };
            };
        };
    };

    // Formats the different operation arguements into
    // a `TransactionFromRequest`, an new internal type to access fields easier for icrc2.
    public func create_transfer_from_req(
        args : T.TransferFromArgs,
        caller : Principal,
        tx_kind : T.ICRC2TxKind,
    ) : T.TransactionFromRequest {

        let encoded = {
            from = Account.encode(args.from_subaccount);
            to = Account.encode(args.to);
        };

        {
            args with kind = #transfer_from;
            from = args.from_subaccount;
            caller;
            encoded;
        };
    };

    public func create_approve_req(
        args : T.ApproveArgs,
        owner : Principal,
        tx_kind : T.OperationKind,
    ) : T.ApproveTxRequest {

        let from = {
            owner;
            subaccount = args.from_subaccount;
        };

        let to = {
            owner = args.spender;
            subaccount = null;
        };

        let encoded = {
            from = Account.encode(from);
            to = Account.encode(to);
        };

        {
            kind = tx_kind;
            from = from;
            spender = to;
            amount = args.amount;
            expires_at = args.expires_at;
            fee = args.fee;
            memo = args.memo;
            created_at_time = args.created_at_time;
            expected_allowance = args.expected_allowance;
            // args with kind = #approve;
            encoded;
        };
    };

    // Transforms the transaction kind from `variant` to `Text`
    public func kind_to_text(kind : T.TxKind) : Text {
        switch (kind) {
            case (#mint) "MINT";
            case (#burn) "BURN";
            case (#transfer) "TRANSFER";
        };
    };

    // Formats the tx request into a finalised transaction
    public func req_to_tx(tx_req : T.TransactionRequest, index : Nat) : T.Transaction {

        {
            kind = kind_to_text(tx_req.kind);
            mint = switch (tx_req.kind) {
                case (#mint) { ?tx_req };
                case (_) null;
            };

            burn = switch (tx_req.kind) {
                case (#burn) { ?tx_req };
                case (_) null;
            };

            transfer = switch (tx_req.kind) {
                case (#transfer) { ?tx_req };
                case (_) null;
            };

            index;
            timestamp = Nat64.fromNat(Int.abs(Time.now()));
        };
    };

    public func approve_req_to_tx(tx_req : T.ApproveTxRequest, index : Nat) : T.ApproveTransaction {

        {
            kind = "APPROVE";
            approve = tx_req;
            index;
            timestamp = Nat64.fromNat(Int.abs(Time.now()));
        };
    };

    public func div_ceil(n : Nat, d : Nat) : Nat {
        (n + d - 1) / d;
    };

    /// Retrieves the balance of an account
    public func get_balance(accounts : T.AccountBalances, encoded_account : T.EncodedAccount) : T.Balance {
        let res = STMap.get(
            accounts,
            Blob.equal,
            Blob.hash,
            encoded_account,
        );

        switch (res) {
            case (?balance) {
                balance;
            };
            case (_) 0;
        };
    };

    /// Retrieves the balance of an account
    public func get_allowance(accounts : T.ApproveBalances, encoded_account : T.EncodedAccount) : T.Allowance {
        let res = STMap.get(
            accounts,
            Blob.equal,
            Blob.hash,
            encoded_account,
        );

        switch (res) {
            case (?balance) {
                balance;
            };
            case (_) {
                {
                    allowance = 0;
                    expires_at = null;
                };
            };
        };
    };

    /// Updates the balance of an account
    public func update_balance(
        accounts : T.AccountBalances,
        encoded_account : T.EncodedAccount,
        update : (T.Balance) -> T.Balance,
    ) {
        let prev_balance = get_balance(accounts, encoded_account);
        let updated_balance = update(prev_balance);

        if (updated_balance != prev_balance) {
            STMap.put(
                accounts,
                Blob.equal,
                Blob.hash,
                encoded_account,
                updated_balance,
            );
        };
    };

    public func update_approve_balance(
        accounts : T.ApproveBalances,
        encoded_account : T.EncodedAccount,
        update_allowance : (T.Allowance) -> T.Allowance,
        change_expires_at : Bool,
    ) {
        let prev_balance = get_allowance(accounts, encoded_account);
        let updated_balance = update_allowance(prev_balance);

        let prev_allowance = prev_balance.allowance;
        let prev_expires_at = prev_balance.expires_at;

        let updated_allowance = updated_balance.allowance;
        let updated_expires_at = updated_balance.expires_at;

        // update expire time
        var expires_at : ?Nat64 = null;
        if (change_expires_at) {
            expires_at := updated_expires_at;
        } else {
            expires_at := prev_expires_at;
        };

        let insert_balance = {
            allowance = updated_allowance;
            expires_at;
        };

        if (updated_balance != prev_balance) {
            STMap.put(
                accounts,
                Blob.equal,
                Blob.hash,
                encoded_account,
                insert_balance,
            );
        };
    };

    // Transfers tokens from the sender to the
    // recipient in the tx request
    public func transfer_balance(
        token : T.TokenData,
        tx_req : T.TransactionRequest,
    ) {
        let { encoded; amount } = tx_req;

        update_balance(
            token.accounts,
            encoded.from,
            func(balance) {
                balance - amount;
            },
        );

        update_balance(
            token.accounts,
            encoded.to,
            func(balance) {
                balance + amount;
            },
        );
    };

    public func approve(
        token : T.TokenData,
        tx_req : T.ApproveTxRequest,
    ) {
        let { encoded; amount; expires_at } = tx_req;

        update_approve_balance(
            token.approve_accounts,
            gen_account_from_two_account(encoded.from, encoded.to),
            func(balance) {
                {
                    allowance = amount;
                    expires_at = expires_at;
                };
            },
            true,
        );
    };

    /// create an account from Approver as `from` account and Spender as `to` account
    public func gen_account_from_two_account(from : T.EncodedAccount, to : T.EncodedAccount) : T.EncodedAccount {
        let from_buffer : Buffer.Buffer<Nat8> = Buffer.fromArray(Blob.toArray(from));
        let to_buffer : Buffer.Buffer<Nat8> = Buffer.fromArray(Blob.toArray(to));
        from_buffer.append(to_buffer);
        let final_array = Buffer.toArray(from_buffer);
        Blob.fromArray(final_array);
    };

    public func mint_balance(
        token : T.TokenData,
        encoded_account : T.EncodedAccount,
        amount : T.Balance,
    ) {
        update_balance(
            token.accounts,
            encoded_account,
            func(balance) {
                balance + amount;
            },
        );

        token._minted_tokens += amount;
    };

    public func burn_balance(
        token : T.TokenData,
        encoded_account : T.EncodedAccount,
        amount : T.Balance,
    ) {
        update_balance(
            token.accounts,
            encoded_account,
            func(balance) {
                balance - amount;
            },
        );

        token._burned_tokens += amount;
    };

    public func decrease_allowance(
        token : T.TokenData,
        encoded_account : T.EncodedAccount,
        amount : T.Balance,
    ) {
        update_approve_balance(
            token.approve_accounts,
            encoded_account,
            func(balance) {
                {
                    allowance = balance.allowance - amount;
                    expires_at = null;
                };
            },
            false,
        );

    };

    // Stable Buffer Module with some additional functions
    public let SB = {
        StableBuffer with slice = func<A>(buffer : T.StableBuffer<A>, start : Nat, end : Nat) : [A] {
            let size = SB.size(buffer);
            if (start >= size) {
                return [];
            };

            let slice_len = (Nat.min(end, size) - start) : Nat;

            Array.tabulate(
                slice_len,
                func(i : Nat) : A {
                    SB.get(buffer, i + start);
                },
            );
        };

        toIterFromSlice = func<A>(buffer : T.StableBuffer<A>, start : Nat, end : Nat) : Iter.Iter<A> {
            if (start >= SB.size(buffer)) {
                return Itertools.empty();
            };

            Iter.map(
                Itertools.range(start, Nat.min(SB.size(buffer), end)),
                func(i : Nat) : A {
                    SB.get(buffer, i);
                },
            );
        };

        appendArray = func<A>(buffer : T.StableBuffer<A>, array : [A]) {
            for (elem in array.vals()) {
                SB.add(buffer, elem);
            };
        };

        getLast = func<A>(buffer : T.StableBuffer<A>) : ?A {
            let size = SB.size(buffer);

            if (size > 0) {
                SB.getOpt(buffer, (size - 1) : Nat);
            } else {
                null;
            };
        };

        capacity = func<A>(buffer : T.StableBuffer<A>) : Nat {
            buffer.elems.size();
        };

        _clearedElemsToIter = func<A>(buffer : T.StableBuffer<A>) : Iter.Iter<A> {
            Iter.map(
                Itertools.range(buffer.count, buffer.elems.size()),
                func(i : Nat) : A {
                    buffer.elems[i];
                },
            );
        };
    };
};
