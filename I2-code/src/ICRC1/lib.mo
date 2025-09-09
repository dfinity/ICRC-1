import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import EC "mo:base/ExperimentalCycles";

import Itertools "mo:itertools/Iter";
import StableTrieMap "mo:StableTrieMap";

import Account "Account";
import T "Types";
import Utils "Utils";
import Transfer "Transfer";
import Archive "Canisters/Archive";

/// The ICRC1 class with all the functions for creating an
/// ICRC1 token on the Internet Computer
module {
    let { SB } = Utils;

    public type Account = T.Account;
    public type Subaccount = T.Subaccount;
    public type AccountBalances = T.AccountBalances;

    public type Transaction = T.Transaction;
    public type Balance = T.Balance;
    public type TransferArgs = T.TransferArgs;
    public type TransferFromArgs = T.TransferFromArgs;
    public type Mint = T.Mint;
    public type BurnArgs = T.BurnArgs;
    public type TransactionRequest = T.TransactionRequest;
    public type TransferError = T.TransferError;

    public type SupportedStandard = T.SupportedStandard;

    public type InitArgs = T.InitArgs;
    public type TokenInitArgs = T.TokenInitArgs;
    public type TokenData = T.TokenData;
    public type MetaDatum = T.MetaDatum;
    public type TxLog = T.TxLog;
    public type TxIndex = T.TxIndex;

    public type TokenInterface = T.TokenInterface;
    public type RosettaInterface = T.RosettaInterface;
    public type FullInterface = T.FullInterface;

    public type ArchiveInterface = T.ArchiveInterface;

    public type GetTransactionsRequest = T.GetTransactionsRequest;
    public type GetTransactionsResponse = T.GetTransactionsResponse;
    public type QueryArchiveFn = T.QueryArchiveFn;
    public type TransactionRange = T.TransactionRange;
    public type ArchivedTransaction = T.ArchivedTransaction;

    public type TransferResult = T.TransferResult;
    public type TransferFromResult = T.TransferFromResult;

    public let MAX_TRANSACTIONS_IN_LEDGER = 2000;
    public let MAX_TRANSACTION_BYTES : Nat64 = 196;
    public let MAX_TRANSACTIONS_PER_REQUEST = 5000;

    public type ApproveArgs = T.ApproveArgs;

    public type AllowanceArgs = T.AllowanceArgs;

    public type Allowance = T.Allowance;

    public type ApproveResult = T.ApproveResult;

    /// Initialize a new ICRC-1 token
    public func init(args : T.InitArgs) : T.TokenData {
        let {
            name;
            symbol;
            decimals;
            fee;
            minting_account;
            max_supply;
            initial_balances;
            min_burn_amount;
            advanced_settings;
        } = args;

        var _burned_tokens = 0;
        var permitted_drift = 60_000_000_000;
        var transaction_window = 86_400_000_000_000;

        switch (advanced_settings) {
            case (?options) {
                _burned_tokens := options.burned_tokens;
                permitted_drift := Nat64.toNat(options.permitted_drift);
                transaction_window := Nat64.toNat(options.transaction_window);
            };
            case (null) {};
        };

        if (not Account.validate(minting_account)) {
            Debug.trap("minting_account is invalid");
        };

        let accounts : T.AccountBalances = StableTrieMap.new();

        let approve_accounts : T.ApproveBalances = StableTrieMap.new();

        var _minted_tokens = _burned_tokens;

        for ((i, (account, balance)) in Itertools.enumerate(initial_balances.vals())) {

            if (not Account.validate(account)) {
                Debug.trap(
                    "Invalid Account: Account at index " # debug_show i # " is invalid in 'initial_balances'"
                );
            };

            let encoded_account = Account.encode(account);

            StableTrieMap.put(
                accounts,
                Blob.equal,
                Blob.hash,
                encoded_account,
                balance,
            );

            _minted_tokens += balance;
        };

        {
            name = name;
            symbol = symbol;
            decimals;
            var _fee = fee;
            max_supply;
            var _minted_tokens = _minted_tokens;
            var _burned_tokens = _burned_tokens;
            min_burn_amount;
            minting_account;
            accounts;
            approve_accounts;
            metadata = Utils.init_metadata(args);
            supported_standards = Utils.init_standards();
            transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            approve_transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            // approve_transactions = SB.initPresized(MAX_TRANSACTIONS_IN_LEDGER);
            permitted_drift;
            transaction_window;
            archive = {
                var canister = actor ("aaaaa-aa");
                var stored_txs = 0;
            };
        };
    };

    /// Retrieve the name of the token
    public func name(token : T.TokenData) : Text {
        token.name;
    };

    /// Retrieve the symbol of the token
    public func symbol(token : T.TokenData) : Text {
        token.symbol;
    };

    /// Retrieve the number of decimals specified for the token
    public func decimals({ decimals } : T.TokenData) : Nat8 {
        decimals;
    };

    /// Retrieve the fee for each transfer
    public func fee(token : T.TokenData) : T.Balance {
        token._fee;
    };

    /// Set the fee for each transfer
    public func set_fee(token : T.TokenData, fee : Nat) {
        token._fee := fee;
    };

    /// Retrieve all the metadata of the token
    public func metadata(token : T.TokenData) : [T.MetaDatum] {
        SB.toArray(token.metadata);
    };

    /// Returns the total supply of circulating tokens
    public func total_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens - token._burned_tokens;
    };

    /// Returns the total supply of minted tokens
    public func minted_supply(token : T.TokenData) : T.Balance {
        token._minted_tokens;
    };

    /// Returns the total supply of burned tokens
    public func burned_supply(token : T.TokenData) : T.Balance {
        token._burned_tokens;
    };

    /// Returns the maximum supply of tokens
    public func max_supply(token : T.TokenData) : T.Balance {
        token.max_supply;
    };

    /// Returns the account with the permission to mint tokens
    ///
    /// Note: **The minting account can only participate in minting
    /// and burning transactions, so any tokens sent to it will be
    /// considered burned.**

    public func minting_account(token : T.TokenData) : T.Account {
        token.minting_account;
    };

    /// Retrieve the balance of a given account
    public func balance_of({ accounts } : T.TokenData, account : T.Account) : T.Balance {
        let encoded_account = Account.encode(account);
        Utils.get_balance(accounts, encoded_account);
    };

    /// Retrieve the balance of a given account and spender
    public func get_allowance_of({ approve_accounts } : T.TokenData, account : T.Account, spender : Account) : T.Allowance {
        let encoded_account = Account.encode(account);
        let encoded_account_spender = Account.encode(spender);
        let gen_account = Utils.gen_account_from_two_account(encoded_account, encoded_account_spender);
        Utils.get_allowance(approve_accounts, gen_account);
    };

    /// Returns an array of standards supported by this token
    public func supported_standards(token : T.TokenData) : [T.SupportedStandard] {
        SB.toArray(token.supported_standards);
    };

    /// Formats a float to a nat balance and applies the correct number of decimal places
    public func balance_from_float(token : T.TokenData, float : Float) : T.Balance {
        if (float <= 0) {
            return 0;
        };

        let float_with_decimals = float * (10 ** Float.fromInt(Nat8.toNat(token.decimals)));

        Int.abs(Float.toInt(float_with_decimals));
    };

    /// Transfers tokens from one account to another account (minting and burning included)
    public func transfer(
        token : T.TokenData,
        args : T.TransferArgs,
        caller : Principal,
    ) : async* T.TransferResult {

        let from = {
            owner = caller;
            subaccount = args.from_subaccount;
        };

        let tx_kind = if (from == token.minting_account) {
            #mint;
        } else if (args.to == token.minting_account) {
            #burn;
        } else {
            #transfer;
        };

        let tx_req = Utils.create_transfer_req(args, caller, tx_kind);

        switch (Transfer.validate_request(token, tx_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount } = tx_req;

        // process transaction
        switch (tx_req.kind) {
            case (#mint) {
                Utils.mint_balance(token, encoded.to, amount);
            };
            case (#burn) {
                Utils.burn_balance(token, encoded.from, amount);
            };
            case (#transfer) {
                Utils.transfer_balance(token, tx_req);

                // burn fee
                Utils.burn_balance(token, encoded.from, token._fee);
            };
        };

        // store transaction
        let index = SB.size(token.transactions) + token.archive.stored_txs;
        let tx = Utils.req_to_tx(tx_req, index);
        SB.add(token.transactions, tx);

        // transfer transaction to archive if necessary
        await* update_canister(token);

        #Ok(tx.index);
    };

    /// Transfers tokens from one account to another account (minting and burning included)
    public func transfer_from(
        token : T.TokenData,
        args : T.TransferFromArgs,
        caller : Principal,
    ) : async* T.TransferFromResult {

        let tx_kind = #transfer_from;

        let tx_transfer_from_req = Utils.create_transfer_from_req(args, caller, tx_kind);

        switch (Transfer.validate_transfer_from_request(token, tx_transfer_from_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        // icrc2 storage is complete, use normal transfer instead
        let normal_transfer_args = {
            from_subaccount = tx_transfer_from_req.from.subaccount;
            to = tx_transfer_from_req.to;
            amount = tx_transfer_from_req.amount;
            fee = tx_transfer_from_req.fee;
            memo = tx_transfer_from_req.memo;
            created_at_time = tx_transfer_from_req.created_at_time;
        };

        let normal_tx_kind = #transfer;
        let tx_req = Utils.create_transfer_req(normal_transfer_args, 
            args.from_subaccount.owner, 
            normal_tx_kind
        );

        switch (Transfer.validate_request(token, tx_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount } = tx_req;

        // process transaction
        Utils.transfer_balance(token, tx_req);

        // burn fee
        Utils.burn_balance(token, encoded.from, token._fee);

        // decrease allowance
        let caller_encoded = Account.encode({
            owner = caller;
            subaccount = null;
        });
        let allowance_key_account = Utils.gen_account_from_two_account(encoded.from, caller_encoded);
        Utils.decrease_allowance(token, allowance_key_account, amount);

        // store transaction
        let index = SB.size(token.transactions) + token.archive.stored_txs;
        let tx = Utils.req_to_tx(tx_req, index);
        SB.add(token.transactions, tx);

        // transfer transaction to archive if necessary
        await* update_canister(token);

        #Ok(tx.index);
    };
    /// Approve tokens from one account to another account
    public func approve(token : T.TokenData, args : T.ApproveArgs, caller : Principal) : async* T.ApproveResult {

        let from = {
            owner = caller;
            subaccount = args.from_subaccount;
        };

        let tx_kind = #approve;

        let tx_req = Utils.create_approve_req(args, caller, tx_kind);

        switch (Transfer.validate_approve_request(token, tx_req)) {
            case (#err(errorType)) {
                return #Err(errorType);
            };
            case (#ok(_)) {};
        };

        let { encoded; amount } = tx_req;

        // process transaction
        switch (tx_req.kind) {
            case (#approve) {
                Utils.approve(token, tx_req);

                // burn fee
                // attention: fee is from caller account
                Utils.burn_balance(token, encoded.from, token._fee);
            };
        };

        // store transaction
        let index = SB.size(token.approve_transactions) + token.archive.stored_txs;
        let tx = Utils.approve_req_to_tx(tx_req, index);
        SB.add(token.approve_transactions, tx);

        // transfer transaction to archive if necessary
        await* update_canister(token);

        #Ok(tx.index);
    };

    /// Helper function to mint tokens with minimum args
    public func mint(token : T.TokenData, args : T.Mint, caller : Principal) : async* T.TransferResult {

        if (caller != token.minting_account.owner) {
            return #Err(
                #GenericError {
                    error_code = 401;
                    message = "Unauthorized: Only the minting_account can mint tokens.";
                }
            );
        };

        let transfer_args : T.TransferArgs = {
            args with from_subaccount = token.minting_account.subaccount;
            fee = null;
        };

        await* transfer(token, transfer_args, caller);
    };

    /// Helper function to burn tokens with minimum args
    public func burn(token : T.TokenData, args : T.BurnArgs, caller : Principal) : async* T.TransferResult {

        let transfer_args : T.TransferArgs = {
            args with to = token.minting_account;
            fee = null;
        };

        await* transfer(token, transfer_args, caller);
    };

    /// Returns the total number of transactions that have been processed by the given token.
    public func total_transactions(token : T.TokenData) : Nat {
        let { archive; transactions } = token;
        archive.stored_txs + SB.size(transactions);
    };

    /// Retrieves the transaction specified by the given `tx_index`
    public func get_transaction(token : T.TokenData, tx_index : T.TxIndex) : async* ?T.Transaction {
        let { archive; transactions } = token;

        let archived_txs = archive.stored_txs;

        if (tx_index < archive.stored_txs) {
            await archive.canister.get_transaction(tx_index);
        } else {
            let local_tx_index = (tx_index - archive.stored_txs) : Nat;
            SB.getOpt(token.transactions, local_tx_index);
        };
    };

    /// Retrieves the transactions specified by the given range
    public func get_transactions(token : T.TokenData, req : T.GetTransactionsRequest) : T.GetTransactionsResponse {
        let { archive; transactions } = token;

        var first_index = 0xFFFF_FFFF_FFFF_FFFF; // returned if no transactions are found

        let req_end = req.start + req.length;
        let tx_end = archive.stored_txs + SB.size(transactions);

        var txs_in_canister : [T.Transaction] = [];

        if (req.start < tx_end and req_end >= archive.stored_txs) {
            first_index := Nat.max(req.start, archive.stored_txs);
            let tx_start_index = (first_index - archive.stored_txs) : Nat;

            txs_in_canister := SB.slice(transactions, tx_start_index, req.length);
        };

        let archived_range = if (req.start < archive.stored_txs) {
            {
                start = req.start;
                end = Nat.min(
                    archive.stored_txs,
                    (req.start + req.length) : Nat,
                );
            };
        } else {
            { start = 0; end = 0 };
        };

        let txs_in_archive = (archived_range.end - archived_range.start) : Nat;

        let size = Utils.div_ceil(txs_in_archive, MAX_TRANSACTIONS_PER_REQUEST);

        let archived_transactions = Array.tabulate(
            size,
            func(i : Nat) : T.ArchivedTransaction {
                let offset = i * MAX_TRANSACTIONS_PER_REQUEST;
                let start = offset + archived_range.start;
                let length = Nat.min(
                    MAX_TRANSACTIONS_PER_REQUEST,
                    archived_range.end - start,
                );

                let callback = token.archive.canister.get_transactions;

                { start; length; callback };
            },
        );

        {
            log_length = txs_in_archive + txs_in_canister.size();
            first_index;
            transactions = txs_in_canister;
            archived_transactions;
        };
    };

    // Updates the token's data and manages the transactions
    //
    // **added at the end of any function that creates a new transaction**
    func update_canister(token : T.TokenData) : async* () {
        let txs_size = SB.size(token.transactions);

        if (txs_size >= MAX_TRANSACTIONS_IN_LEDGER) {
            await* append_transactions(token);
        };
    };

    // Moves the transactions from the ICRC1 canister to the archive canister
    // and returns a boolean that indicates the success of the data transfer
    func append_transactions(token : T.TokenData) : async* () {
        let { archive; transactions } = token;

        if (archive.stored_txs == 0) {
            EC.add(200_000_000_000);
            archive.canister := await Archive.Archive();
        };

        let res = await archive.canister.append_transactions(
            SB.toArray(transactions)
        );

        switch (res) {
            case (#ok(_)) {
                archive.stored_txs += SB.size(transactions);
                SB.clear(transactions);
            };
            case (#err(_)) {};
        };
    };

};
