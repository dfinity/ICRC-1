# ICRC-2 Implementation
This repo contains the implementation of the 
[ICRC-2](https://github.com/dfinity/ICRC-1/blob/main/standards/ICRC-2/README.md). 

## References 
- [ICRC-1](https://github.com/NatLabs/icrc1)
- [ICRC1 test](https://github.com/NatLabs/icrc1/blob/main/example/icrc1/main.mo)

 
## Getting Started 
- Expose the ICRC-1 from your canister 
  - Import the `icrc1` lib and expose them in an `actor` class.
  

  ```motoko
    git clone https://github.com/JingJingZhang9/I3-code.git
    dfx start --background --clean

    dfx deploy icrc1 --argument '( record {                     
        name = "<Insert Token Name>";                         
        symbol = "<Insert Symbol>";                           
        decimals = 6;                                           
        fee = 1_000_000;                                        
        max_supply = 1_000_000_000_000;                         
        initial_balances = vec {                                
            record {                                            
                record {                                        
                    owner = principal "<Insert Principal>";   
                    subaccount = null;                          
                };                                              
                100_000_000                                 
            }                                                   
        };                                                      
        min_burn_amount = 10_000;                         
        minting_account = null;                                 
        advanced_settings = null;                               
    })'
  ```

- Create a token dynamically from a canister
    ```motoko
        import Nat8 "mo:base/Nat8";
        import Token "mo:icrc1/ICRC1/Canisters/Token";

        actor{
            let decimals = 8; // replace with your chosen number of decimals

            func add_decimals(n: Nat): Nat{
                n * 10 ** decimals
            };

            let pre_mint_account = {
                owner = Principal.fromText("<Insert Principal>");
                subaccount = null;
            };

            let token_canister = Token.Token({
                name = "<Insert Token Name>";
                symbol = "<Insert Token Symbol>";
                decimals = Nat8.fromNat(decimals);
                fee = add_decimals(1);
                max_supply = add_decimals(1_000_000);

                // pre-mint 100,000 tokens for the account
                initial_balances = [(pre_mint_account, add_decimals(100_000))]; 

                min_burn_amount = add_decimals(10);
                minting_account = null; // defaults to the canister id of the caller
                advanced_settings = null; 
            });
        }
    ```

> The fields for the `advanced_settings` record are documented [here](./docs/ICRC1/Types.md#type-advancedsettings)

## Textual Representation of the ICRC-2 
This library implements the https://github.com/dfinity/ICRC-1/blob/main/standards/ICRC-2/README.md .

ICRC-2 is an extension of the ICRC-1 standard. ICRC-2 provides a way for account owners to delegate token transfer authorization to a third party, allowing the third party to perform transfers on behalf of the owner:
icrc2_approve: Authorizes the spender to transfer a certain amount of tokens on behalf of the caller from the account { owner = caller; subaccount = from_subaccount }. The number of transfers the spender can initiate from the caller's account is unlimited as long as the total amounts and fees of these transfers do not exceed the allowance.
icrc2_transfer_from: Transfers a certain amount of tokens between two accounts.


## Tests
#### Internal Tests
- Download and Install [vessel](https://github.com/dfinity/vessel)
- Run `make test` 
- Run `make actor-test`



## Funding

This library was initially incentivized by [ICDevs](https://icdevs.org/). You can view more about the bounty on the [forum](https://forum.dfinity.org/t/completed-icdevs-org-bounty-26-icrc-1-motoko-up-to-10k/14868/54) or [website](https://icdevs.org/bounties/2022/08/14/ICRC-1-Motoko.html). The bounty was funded by The ICDevs.org community and the DFINITY Foundation and the award was paid to [@NatLabs](https://github.com/NatLabs). If you use this library and gain value from it, please consider a [donation](https://icdevs.org/donations.html) to ICDevs.
