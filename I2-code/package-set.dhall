let aviate_labs = https://github.com/aviate-labs/package-set/releases/download/v0.1.4/package-set.dhall sha256:30b7e5372284933c7394bad62ad742fec4cb09f605ce3c178d892c25a1a9722e
let vessel_package_set =
      https://github.com/dfinity/vessel-package-set/releases/download/mo-0.6.20-20220131/package-set.dhall

let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [] : List Package

let overrides = [
    {
       name = "StableTrieMap",
       version = "main",
       repo = "https://github.com/NatLabs/StableTrieMap",
       dependencies = ["base"] : List Text
    },
    {
       name = "StableBuffer",
       version = "v0.2.0",
       repo = "https://github.com/canscale/StableBuffer",
       dependencies = ["base"] : List Text
    },
    {
       name = "itertools",
       version = "main",
       repo = "https://github.com/NatLabs/Itertools.mo",
       dependencies = ["base"] : List Text
    },
    {
       name = "base",
       version = "moc-0.7.4",
       repo = "https://github.com/dfinity/motoko-base",
       dependencies = ["base"] : List Text
    },
] : List Package

in  aviate_labs # vessel_package_set # overrides
