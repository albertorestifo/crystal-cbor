# Crystal CBOR

[![builds.sr.ht status](https://builds.sr.ht/~arestifo/crystal-cbor.svg)](https://builds.sr.ht/~arestifo/crystal-cbor?)

This library implements the [RFC7049: Concise Binary Object Representation (CBOR)][rfc]
in Crystal.

- [Installation](#installation)
- [Usage](#usage)
- [Supported Tags](#supported-tags)
- [Limitations](#limitations)
- [Community](#community)
- [Contributing](#contributing)

## Features

- Full RFC 7049
- Tested against all examples in the RFC 7049
- Simple and powerful API inspired by the standard library JSON
- Full support for diagnostic notation
- Support for a [wide range of IANA CBOR Tags](#supported-tags)
- Support custom CBOR Tags

## Example

```crystal
require "cbor"

class Location
  include CBOR::Serializable

  @[CBOR::Field(key: "lat")]
  property latitude : Float64

  @[CBOR::Field(key: "lng")]
  property longitude : Float64
end

class House
  include CBOR::Serializable

  property address : String
  property location : Location?
end

data = {
  "address" => "Crystal Road 1234",
  "location" => { "lat" => 12.3, "lng" => 34.5 }
}
cbor = data.to_cbor         # => Bytes[...]
CBOR::Diagnostic.to_s(cbor) # => {"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}

house = House.from_cbor(cbor)
house.address                 # => "Crystal Road 1234"
house.location                # => #<Location:0x10cd93d80 @latitude=12.3, @longitude=34.5>
bytes = house.to_cbor         # => Bytes[...]
CBOR::Diagnostic.to_s(bytes)  # => {"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}

data_array = [data]
cbor_array = data_array.to_cbor # => Bytes[...]
CBOR::Diagnostic.to_s(cbor)     # => [{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]}

houses = Array(House).from_cbor(cbor_array)
houses.size                  # => 1
bytes = houses.to_cbor       # => Bytes[...]
CBOR::Diagnostic.to_s(bytes) # => [{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]
```

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     cbor:
       git: https://git.sr.ht/~arestifo/crystal-cbor
   ```

2. Run `shards install`

## Usage

Including `CBOR::Serializable` will create `#to_cbor` and `self.from_cbor` methods
on the current class, and a constructor which takes a `CBOR::Decoder`.

By default, these methods serialize into a cbor map containing the value of
every instance variable, the keys being the instance variable name.

Most primitives and collections are supported as instance variable values (string,
integer, array, hash, etc.), along with objects which define to_cbor and a
constructor taking a `CBOR::Decoder`.

Union types are also supported, including unions with `nil`. If multiple types
in a union parse correctly, it is undefined which one will be chosen.

To change how individual instance variables are parsed and serialized,
the annotation `CBOR::Field` can be placed on the instance variable.
Annotating property, getter and setter macros is also allowed.

```crystal
require "cbor"

class A
  include CBOR::Serializable

  @[CBOR::Field(key: "my_key")]
  getter a : Int32?
end
```

### `CBOR::Field` properties

- **ignore**: if `true` skip this field in serialization and deserialization
  (by default `false`)
- **key**: the value of the key in the json object (by default the name of the
  instance variable)
- **converter**: specify an alternate type for parsing and generation.
  The converter must define `from_cbor(CBOR::Decoder)` and
  `to_cbor(value, CBOR::Builder)` as class methods. Examples of converters are
  `Time::Format::RFC_333` and `Time::EpochConverter` for `Time`.
- **presence**: if `true`, a `@{{key}}_present` instance variable will be generated
  when the key was present (even if it has a `null` value), `false` by default
- **emit_null**: if `true`, emits a `null` value for nilable property
  (by default nulls are not emitted)
- **nil_as_undefined**: if `true`, when the value is `nil`, it is emitted as
  `undefined` (by default `nil` are encoded as `null`)

Deserialization also respects default values of variables:

```crystal
require "cbor"

struct A
  include CBOR::Serializable
  @a : Int32
  @b : Float64 = 1.0
end

A.from_cbor({"a" => 1}.to_cbor) # => A(@a=1, @b=1.0)
```

### Extensions: `CBOR::Serializable::Unmapped`

If the `CBOR::Serializable::Unmapped` module is included, unknown properties in
the CBOR document will be stored in a `Hash(String, CBOR::Type)`.

On serialization, any keys inside `cbor_unmapped` will be serialized and appended
to the current cbor map.

```crystal
require "cbor"

struct A
  include CBOR::Serializable
  include CBOR::Serializable::Unmapped
  @a : Int32
end

a = A.from_cbor({"a" => 1, "b" => 2}.to_cbor) # => A(@cbor_unmapped={"b" => 2}, @a=1)
bytes = a.to_cbor                             # => Bytes[...]
CBOR::Diagnostic.to_s(bytes)                  # => {"a": 1, "b": 2}
```

### Class annotation `CBOR::Serializable::Options`

supported properties:

- **emit_nulls**: if `true`, emits a `null` value for all nilable properties
  (by default nulls are not emitted)
- **nil_as_undefined**: if `true`, emits a `nil` value as undefined
  (by default nil emits `null`)

```crystal
require "cbor"

@[CBOR::Serializable::Options(emit_nulls: true)]
class A
  include CBOR::Serializable
  @a : Int32?
end
```

## Supported tags

All the tags specified in [section 2.4 of RFC 7049][rfc-tags] are supported
and the values are encoded in the respective Crystal types:

- `Time`
- `BigInt`
- `BigDecimal`

## Limitations

### Maximum Array/String array/Bytes array length

The spec allows for the maximum length of arrays, string arrays and bytes array
to be a `UInt64`.

While this library supports lengths expressed as a `UInt64`, it must not exceed
`Int32::MAX`.

## Community

If you're stuck and need help, if you have any questions, or if you simply want
to stay up to date with the latest news and developments, you can subscribe to
the [crystal-cbor mailing list][mailing-list].

If you found an issue, you can [open an issue on the ticket tracker][tickets].

## Contributing

The code is hosted on SourceHut and the development happens over the
[crystal-cbor mailing list][mailing-list].

- For issues and feature requests, you can [open and issue in the ticket tracker][tickets].

- For code contributions You can send a patch to: [~arestifo/crystal-cbor@lists.sr.ht](mailto:~arestifo/crystal-cbor@lists.sr.ht).

To learn how to use `git send-email`, there is a great step-by-step tutorial
at [git-send-email.io](https://git-send-email.io/).
You might also want to read the [mailing list etiquette](https://man.sr.ht/lists.sr.ht/etiquette.md).

[rfc]: https://tools.ietf.org/html/rfc7049
[rfc-tags]: https://tools.ietf.org/html/rfc7049#section-2.4
[mailing-list]: https://lists.sr.ht/~arestifo/crystal-cbor
[tickets]: https://todo.sr.ht/~arestifo/crystal-cbor
