import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat8 "mo:base/Nat8";
import Option "mo:base/Option";
import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Time "mo:base/Time";

import Itertools "mo:itertools/Iter";
import StableBuffer "mo:StableBuffer/StableBuffer";
import STMap "mo:StableTrieMap";

import Account "Account";

import T "Types";
import Utils "Utils";

module {
    let { SB } = Utils;

    /// Checks if a transaction memo is valid
    public func validate_memo(memo : ?T.Memo) : Bool {
        switch (memo) {
            case (?bytes) {
                bytes.size() <= 32;
            };
            case (_) true;
        };
    };

    /// Checks if the `created_at_time` of a transfer request is before the accepted time range
    public func is_too_old(token : T.TokenData, created_at_time : Nat64) : Bool {
        let { permitted_drift; transaction_window } = token;

        let lower_bound = Time.now() - transaction_window - permitted_drift;
        Nat64.toNat(created_at_time) < lower_bound;
    };

    /// Checks if the `created_at_time` of a transfer request has not been reached yet relative to the canister's time.
    public func is_in_future(token : T.TokenData, created_at_time : Nat64) : Bool {
        let upper_bound = Time.now() + token.permitted_drift;
        Nat64.toNat(created_at_time) > upper_bound;
    };

    /// Checks if there is a duplicate transaction that matches the transfer request in the main canister.
    ///
    /// If a duplicate is found, the function returns an error (`#err`) with the duplicate transaction's index.
    public func deduplicate(token : T.TokenData, tx_req : T.TransactionRequest) : Result.Result<(), Nat> {
        // only deduplicates if created_at_time is set
        if (tx_req.created_at_time == null) {
            return #ok();
        };

        let { transactions = txs; archive } = token;

        var phantom_txs_size = 0;
        let phantom_txs = SB._clearedElemsToIter(txs);
        let current_txs = SB.vals(txs);

        let last_2000_txs = if (archive.stored_txs > 0) {
            phantom_txs_size := SB.capacity(txs) - SB.size(txs);
            Itertools.chain(phantom_txs, current_txs);
        } else {
            current_txs;
        };

        label for_loop for ((i, tx) in Itertools.enumerate(last_2000_txs)) {

            let is_duplicate = switch (tx_req.kind) {
                case (#mint) {
                    switch (tx.mint) {
                        case (?mint) {
                            ignore do ? {
                                if (is_too_old(token, mint.created_at_time!)) {
                                    break for_loop;
                                };
                            };

                            let mint_req : T.Mint = tx_req;

                            mint_req == mint;
                        };
                        case (_) false;
                    };
                };
                case (#burn) {
                    switch (tx.burn) {
                        case (?burn) {
                            ignore do ? {
                                if (is_too_old(token, burn.created_at_time!)) {
                                    break for_loop;
                                };
                            };
                            let burn_req : T.Burn = tx_req;

                            burn_req == burn;
                        };
                        case (_) false;
                    };
                };
                case (#transfer) {
                    switch (tx.transfer) {
                        case (?transfer) {
                            ignore do ? {
                                if (is_too_old(token, transfer.created_at_time!)) {
                                    break for_loop;
                                };
                            };

                            let transfer_req : T.Transfer = tx_req;

                            transfer_req == transfer;
                        };
                        case (_) false;
                    };
                };
            };

            if (is_duplicate) { return #err(tx.index) };
        };

        #ok();
    };

    /// Checks if a transfer fee is valid
    public func validate_fee(
        token : T.TokenData,
        opt_fee : ?T.Balance,
    ) : Bool {
        switch (opt_fee) {
            case (?tx_fee) {
                if (tx_fee < token._fee) {
                    return false;
                };
            };
            case (null) {
                if (token._fee > 0) {
                    return false;
                };
            };
        };

        true;
    };

    /// Checks if a transfer request is valid
    public func validate_request(
        token : T.TokenData,
        tx_req : T.TransactionRequest,
    ) : Result.Result<(), T.TransferError> {

        if (tx_req.from == tx_req.to) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "The sender cannot have the same account as the recipient.";
                })
            );
        };

        if (not Account.validate(tx_req.from)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for sender. " # debug_show (tx_req.from);
                })
            );
        };

        if (not Account.validate(tx_req.to)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for recipient " # debug_show (tx_req.to);
                })
            );
        };

        if (not validate_memo(tx_req.memo)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Memo must not be more than 32 bytes";
                })
            );
        };

        if (tx_req.amount == 0) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Amount must be greater than 0";
                })
            );
        };

        switch (tx_req.kind) {
            case (#transfer) {
                if (not validate_fee(token, tx_req.fee)) {
                    return #err(
                        #BadFee {
                            expected_fee = token._fee;
                        }
                    );
                };

                let balance : T.Balance = Utils.get_balance(
                    token.accounts,
                    tx_req.encoded.from,
                );

                if (tx_req.amount + token._fee > balance) {
                    return #err(#InsufficientFunds { balance });
                };
            };

            case (#mint) {
                if (token.max_supply < token._minted_tokens + tx_req.amount) {
                    let remaining_tokens = (token.max_supply - token._minted_tokens) : Nat;

                    return #err(
                        #GenericError({
                            error_code = 0;
                            message = "Cannot mint more than " # Nat.toText(remaining_tokens) # " tokens";
                        })
                    );
                };
            };
            case (#burn) {
                if (tx_req.to == token.minting_account and tx_req.amount < token.min_burn_amount) {
                    return #err(
                        #BadBurn { min_burn_amount = token.min_burn_amount }
                    );
                };

                let balance : T.Balance = Utils.get_balance(
                    token.accounts,
                    tx_req.encoded.from,
                );

                if (balance < tx_req.amount) {
                    return #err(#InsufficientFunds { balance });
                };
            };
        };

        switch (tx_req.created_at_time) {
            case (null) {};
            case (?created_at_time) {

                if (is_too_old(token, created_at_time)) {
                    return #err(#TooOld);
                };

                if (is_in_future(token, created_at_time)) {
                    return #err(
                        #CreatedInFuture {
                            ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                        }
                    );
                };

                switch (deduplicate(token, tx_req)) {
                    case (#err(tx_index)) {
                        return #err(
                            #Duplicate {
                                duplicate_of = tx_index;
                            }
                        );
                    };
                    case (_) {};
                };
            };
        };

        #ok();
    };

    public func validate_approve_request(
        token : T.TokenData,
        tx_req : T.ApproveTxRequest,
    ) : Result.Result<(), T.ApproveError> {
        // TODO: The spender's allowance for the { owner = caller; subaccount = from_subaccount }
        // increases by the amount (or decreases if the amount is negative). If the total allowance
        // is negative, the ledger MUST reset the allowance to zero.
        if (tx_req.from.owner == tx_req.spender.owner) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "The approve Principal cannot be the same Principal as the approver.";
                })
            );
        };

        if (not Account.validate(tx_req.from)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for sender. " # debug_show (tx_req.from);
                })
            );
        };

        if (not Account.validate(tx_req.spender)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Invalid account entered for recipient " # debug_show (tx_req.spender);
                })
            );
        };

        if (not validate_memo(tx_req.memo)) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Memo must not be more than 32 bytes";
                })
            );
        };
        // seems it's not need to let amount < 0, cause type Nat is >= 0 always
        if (tx_req.amount < 0) {
            return #err(
                #GenericError({
                    error_code = 0;
                    message = "Amount must be greater than or euqal 0";
                })
            );
        };

        switch (tx_req.kind) {
            case (#approve) {
                if (not validate_fee(token, tx_req.fee)) {
                    return #err(
                        #BadFee {
                            expected_fee = token._fee;
                        }
                    );
                };

                let balance : T.Balance = Utils.get_balance(
                    token.accounts,
                    tx_req.encoded.from,
                );

                if (tx_req.amount > balance + token._fee) {
                    return #err(#InsufficientFunds { balance = balance });
                };
            };
        };

        // check expected allowance
        switch (tx_req.expected_allowance) {
            case (null) {};
            case (?expected_allowance) {
                let account_pair = Utils.gen_account_from_two_account(tx_req.encoded.from, tx_req.encoded.to);
                let saved_allowance = Utils.get_allowance(token.approve_accounts, account_pair);
                if (expected_allowance != saved_allowance.allowance) {
                    return #err(
                        #AllowanceChanged {
                            current_allowance = saved_allowance.allowance;
                        }
                    );
                };
            };
        };

        switch (tx_req.created_at_time) {
            case (null) {};
            case (?created_at_time) {

                if (is_too_old(token, created_at_time)) {
                    return #err(#TooOld);
                };

                if (is_in_future(token, created_at_time)) {
                    return #err(
                        #CreatedInFuture {
                            ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                        }
                    );
                };
            };
        };

        #ok();
    };

    /// Checks if a transfer request is valid
    public func validate_transfer_from_request(
        token : T.TokenData,
        tx_req : T.TransactionFromRequest,
    ) : Result.Result<(), T.TransferFromError> {

        let encoded_caller_account = Account.encode({
            owner = tx_req.caller;
            subaccount = null;
            });

        let account_pair = Utils.gen_account_from_two_account(tx_req.encoded.from, encoded_caller_account);
        // check allowance
        let allowance_pair : T.Allowance = Utils.get_allowance(
            token.approve_accounts,
            account_pair,
        );

        if (tx_req.amount > allowance_pair.allowance + token._fee) {
            return #err(#InsufficientAllowance { allowance = allowance_pair.allowance });
        };

        // check balance
        let balance : T.Balance = Utils.get_balance(
            token.accounts,
            tx_req.encoded.from,
        );

        if (tx_req.amount > balance + token._fee) {
            return #err(#InsufficientFunds { balance = balance });
        };

        // check expire time
        // TODO: let expire time be a new type of error
        switch (allowance_pair.expires_at) {
            case (null) {};
            case (?expires_at_time) {
                switch (tx_req.created_at_time) {
                    case (null) {};
                    case (?created_at_time) {
                        if (created_at_time > expires_at_time) {
                            return #err(#InsufficientFunds { balance = 0 });
                        };
                    };
                };
            };
        };

        switch (tx_req.created_at_time) {
            case (null) {};
            case (?created_at_time) {

                if (is_too_old(token, created_at_time)) {
                    return #err(#TooOld);
                };

                if (is_in_future(token, created_at_time)) {
                    return #err(
                        #CreatedInFuture {
                            ledger_time = Nat64.fromNat(Int.abs(Time.now()));
                        }
                    );
                };

                // check deduplicate is in transfer validate_request
            };
        };

        #ok();
    };

};
