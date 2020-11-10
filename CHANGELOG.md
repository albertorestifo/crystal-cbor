# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- The length of objects is now pre-computed, reducing the size of the encoded
  object and speeding up the decoing process. Thanks to Karchnu for his contribution.

## [0.2.1] - 2020-09-29

### Fixed

- Bug when passing an `IO` to `to_cbor`

## [0.2.0] - 2020-06-18

### Changed

- Upgraded to Crystal 0.35.0

## [0.1.1] - 2020-06-02

### Fixed

- Fix encoding of CBOR tags and as a consequence, the encoding of `Time`

## [0.1.0] - 2020-06-01

- Initial Release
