# ICRC1/Account

## Function `validate_subaccount`
``` motoko no-repl
func validate_subaccount(subaccount : ?T.Subaccount) : Bool
```

Checks if a subaccount is valid

## Function `validate`
``` motoko no-repl
func validate(account : T.Account) : Bool
```

Checks if an account is valid

## Function `encode`
``` motoko no-repl
func encode() : T.EncodedAccount
```

Implementation of ICRC1's Textual representation of accounts [Encoding Standard](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1#encoding)

## Function `decode`
``` motoko no-repl
func decode(encoded : T.EncodedAccount) : ?T.Account
```

Implementation of ICRC1's Textual representation of accounts [Decoding Standard](https://github.com/dfinity/ICRC-1/tree/main/standards/ICRC-1#decoding)

## Function `fromText`
``` motoko no-repl
func fromText(encoded : Text) : ?T.Account
```

Converts an ICRC-1 Account from its Textual representation to the `Account` type

## Function `toText`
``` motoko no-repl
func toText(account : T.Account) : Text
```

Converts an ICRC-1 `Account` to its Textual representation
