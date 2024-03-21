## Representation independent hashing

The following pseudocode specifies how to calculate the (representation independent) hash of an element of the Value type.  Some test vectors to check compliance of an implementation with this specification follow.

```
type Value = variant {
    Blob : blob,
    Text : text,
    Nat : nat,
    Int : int,
    Array : vec Value,
    Map : vec (text, Value)
};

Function hash_value(value)
    Initialize hasher as a new instance of SHA256

    Match value with
        Nat:
            Return SHA256_hash(LEB128_encode(value))
        Int:
            Return SHA256_hash(SLEB128_encode(value))
        Text:
            Return SHA256_hash(UTF8_encode(value))
        Blob:
            Return SHA256_hash(value)
        Array:
            For each element in value
                Update hasher with hash_value(element)
            Return hasher.finalize()
        Map:
            Initialize hashes as empty list
            For each (key, val) in value
                Add (SHA256_hash(UTF8_encode(key)), hash_value(val)) to hashes
            Sort hashes in lexicographical order
            For each (key_hash, val_hash) in hashes
                Update hasher with key_hash
                Update hasher with val_hash
            Return hasher.finalize()
        Else:
            Return error "unsupported value type"
End Function

Function LEB128_encode(nat_input)
    Convert nat_input to LEB128 byte encoding
End Function

Function SLEB128_encode(integer_input)
    Convert integer_input to SLEB128 byte encoding
End Function

Function UTF8_encode(text)
    Convert text to UTF-8 byte array and return it
End Function

Function SHA256_hash(data)
    Initialize a new SHA256 hasher
    Update hasher with data
    Return hasher.finalize()
End Function

```

## Test vectors


```ignorelang
input: Nat(42)
expected output: 684888c0ebb17f374298b65ee2807526c066094c701bcc7ebbe1c1095f494fc1
```

```ignorelang
input: Int(-42)
expected output: de5a6f78116eca62d7fc5ce159d23ae6b889b365a1739ad2cf36f925a140d0cc
```


```ignorelang
input: Text("Hello, World!"),
expected output: dffd6021bb2bd5b0af676290809ec3a53191dd81c7f70a4b28688a362182986f
```

```ignorelang
input: Blob(b'\x01\x02\x03\x04')
expected output: 9f64a747e1b97f131fabb6b447296c9b6f0201e79fb3c5356e6c77e89b6a806a
```

```ignorelang
input: Array([Nat(3), Text("foo"), Blob(b'\x05\x06')])
expected output: 514a04011caa503990d446b7dec5d79e19c221ae607fb08b2848c67734d468d6
```

```ignorelang
input: Map([("from", Blob(b'\x00\xab\xcd\xef\x00\x12\x34\x00\x56\x78\x9a\x00\xbc\xde\xf0\x00\x01\x23\x45\x67\x89\x00\xab\xcd\xef\x01')),
            ("to", Blob(b'\x00\xab\x0d\xef\x00\x12\x34\x00\x56\x78\x9a\x00\xbc\xde\xf0\x00\x01\x23\x45\x67\x89\x00\xab\xcd\xef\x01')),
            ("amount", Nat(42)),
            ("created_at", Nat(1699218263)),
            ("memo", Nat(0))
    ])

expected output: c56ece650e1de4269c5bdeff7875949e3e2033f85b2d193c2ff4f7f78bdcfc75
```