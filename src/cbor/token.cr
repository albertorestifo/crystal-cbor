class CBOR::Token
  record NullT, byte_number : Int64
  record BoolT, byte_number : Int64, value : Bool
  record ArrayT, byte_number : Int64, size : UInt32?
  record MapT, byte_number : Int64, size : UInt32?
  record IntT, byte_number : Int64, value : Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64 | Int128
  record FloatT, byte_number : Int64, value : Float64
  record StringT, byte_number : Int64, value : String
  record BytesT, byte_number : Int64, value : Bytes
  record StringArrayT, byte_number : Int64
  record BytesArrayT, byte_number : Int64

  alias T = NullT | BoolT | ArrayT | MapT | IntT | FloatT | StringT | BytesT | StringArrayT | BytesArrayT

  def self.to_s(token : T)
    case token
    when IntT
      token.value.to_s
    when BytesT
      return %(h'') if token.value.empty?
      "h'#{token.value.hexstring}'"
    when NullT
      "null"
    when UndefinedT
      "undefined"
    else
      raise "Diagnostic notation for type #{token.class} not implemented"
    end
  end
end
