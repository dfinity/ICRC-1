import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Time "mo:base/Time";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import SB "mo:StableBuffer/StableBuffer";

import ICRC1 "..";
import Archive "Archive";

shared ({ caller = _owner }) actor class Token(
    init_args : ICRC1.TokenInitArgs
) : async ICRC1.FullInterface {

    let icrc1_args : ICRC1.InitArgs = {
        init_args with minting_account = Option.get(
            init_args.minting_account,
            {
                owner = _owner;
                subaccount = null;
            },
        );
    };

    stable let token = ICRC1.init(icrc1_args);

    /// Functions for the ICRC1 token standard
    public shared query func icrc1_name() : async Text {
        ICRC1.name(token);
    };

    public shared query func icrc1_symbol() : async Text {
        ICRC1.symbol(token);
    };

    public shared query func icrc1_decimals() : async Nat8 {
        ICRC1.decimals(token);
    };

    public shared query func icrc1_fee() : async ICRC1.Balance {
        ICRC1.fee(token);
    };

    public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
        ICRC1.metadata(token);
    };

    public shared query func icrc1_total_supply() : async ICRC1.Balance {
        ICRC1.total_supply(token);
    };

    public shared query func icrc1_minting_account() : async ?ICRC1.Account {
        ?ICRC1.minting_account(token);
    };

    public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
        ICRC1.balance_of(token, args);
    };

    public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
        ICRC1.supported_standards(token);
    };

    public shared ({ caller }) func icrc1_transfer(args : ICRC1.TransferArgs) : async ICRC1.TransferResult {
        await* ICRC1.transfer(token, args, caller);
    };

    public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
        await* ICRC1.mint(token, args, caller);
    };

    public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
        await* ICRC1.burn(token, args, caller);
    };

    public shared ({ caller }) func icrc2_approve(args : ICRC1.ApproveArgs) : async ICRC1.ApproveResult {
        await* ICRC1.approve(token, args, caller);
    };

    public shared ({ caller }) func icrc2_transfer_from(args : ICRC1.TransferFromArgs) : async ICRC1.TransferFromResult {
        await* ICRC1.transfer_from(token, args, caller);
    };

    public shared query func icrc2_allowance(args : ICRC1.AllowanceArgs) : async ICRC1.Allowance {
        ICRC1.get_allowance_of(token, args.account, args.spender);
    };

    // Functions for integration with the rosetta standard
    public shared query func get_transactions(req : ICRC1.GetTransactionsRequest) : async ICRC1.GetTransactionsResponse {
        ICRC1.get_transactions(token, req);
    };

    // Additional functions not included in the ICRC1 standard
    public shared func get_transaction(i : ICRC1.TxIndex) : async ?ICRC1.Transaction {
        await* ICRC1.get_transaction(token, i);
    };

    // Deposit cycles into this canister.
    public shared func deposit_cycles() : async () {
        let amount = ExperimentalCycles.available();
        let accepted = ExperimentalCycles.accept(amount);
        assert (accepted == amount);
    };
};
