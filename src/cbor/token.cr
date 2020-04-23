module CBOR::Token
  record NullT, undefined : Bool = false
  record BoolT, value : Bool
  record IntT, value : Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64 | Int128
  record FloatT, value : Float32 | Float64
  record BytesT, value : Bytes, chunks : Array(Int32)? = nil
  record StringT, value : String, chunks : Array(Int32)? = nil
  record ArrayT, size : Int32? = nil
  record MapT, size : Int32? = nil
  record TagT, id : UInt32

  alias T = NullT |
            BoolT |
            IntT |
            FloatT |
            BytesT |
            StringT |
            ArrayT |
            MapT |
            TagT
end
