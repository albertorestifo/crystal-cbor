# CBOR

[![builds.sr.ht status](https://builds.sr.ht/~arestifo/crystal-cbor.svg)](https://builds.sr.ht/~arestifo/crystal-cbor?)

This library implements the [RFC7049: Concise Binary Object Representation (CBOR)][rfc]
in Crystal.

**WARNING:** This library is still a work in progress.

## Features

- Full support for diagnostic notation
- Assign a field to a type base on the CBOR tag
- Support for a wide range of IANA CBOR Tags (see below)

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

## Development

TODO: Write development instructions here

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
