# CBOR

[![builds.sr.ht status](https://builds.sr.ht/~arestifo/crystal-cbor.svg)](https://builds.sr.ht/~arestifo/crystal-cbor?)

This library implements the [RFC7049: Concise Binary Object Representation (CBOR)][rfc]
in Crystal.

## Limitations

### Maximum Array/String array/Bytes array length

The spec allows for the maximum length of arrays, string arrays and bytes array
to be a `UInt64`.

While this library supports lengths expressed as a `UInt64`, it must not exceed
`Int32::MAX`.

### Diagnostic notation

While this library implements a diagnostic notation to be able to run against
the examples provided in the RFC, the diagnostic notation is not fully
spec-compliant:

- Indefinite length items are not marked with the starting underscore but
  represented as their finite counterparts.

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
