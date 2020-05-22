require "big"

require "./cbor/**"

# TODO: Write documentation for `CBOR`
module CBOR
  VERSION = "0.1.0"

  # Represents CBOR types
  alias Type = Nil |
               Bool |
               String |
               Bytes |
               Array(Type) |
               Hash(Type, Type) |
               Int8 |
               UInt8 |
               Int16 |
               UInt16 |
               Int32 |
               UInt32 |
               Int64 |
               UInt64 |
               Int128 |
               Float32 |
               Float64
end
