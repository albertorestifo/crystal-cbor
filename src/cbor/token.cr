class CBOR::Token
  record NullT, byte_number : Int32
  record BoolT, byte_number : Int32, value : Bool
  record ArrayT, byte_number : Int32, size : UInt32
  record MapT, byte_number : Int32, size : UInt32
  record IntT, byte_number : Int32, value : Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64
  record FloatT, byte_number : Int32, value : Float64
  record StringT, byte_number : Int32, value : String
  record BytesT, byte_number : Int32, value : Bytes

  alias T = NullT | BoolT | ArrayT | MapT | IntT | FloatT | StringT | BytesT

  def self.to_s(token : T)
    case token
    when IntT
      token.value.to_s
    else
      "NOT IMPLEMENTED YET!"
    end
  end
end
