# CBOR

[![builds.sr.ht status](https://builds.sr.ht/~arestifo/crystal-cbor.svg)](https://builds.sr.ht/~arestifo/crystal-cbor?)

This library implements the [RFC7049: Concise Binary Object Representation (CBOR)][rfc]
in Crystal.

## Features

- Full RFC7049 support
- Full support for diagnostic notation
- Assign a field to a type base on the CBOR tag
- Support for a wide range of IANA CBOR Tags

## Limitations

### Half-precision floating point is not supported

Crystal doesn't have a `Float16` type, so half-precision floating point numbers
are not supported for the time being.

### Maximum Array/String array/Bytes array length

The spec allows for the maximum length of arrays, string arrays and bytes array
to be a `UInt64`.

While this library supports lengths expressed as a `UInt64`, it must not exceed
`Int32::MAX`.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     cbor:
       git: https://git.sr.ht/~arestifo/crystal-cbor
   ```

2. Run `shards install`

## Usage

```crystal
require "cbor"
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/your-github-user/cbor/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alberto Restifo](https://github.com/your-github-user) - creator and maintainer

[rfc]: https://tools.ietf.org/html/rfc7049
