class CBOR::Token
  record NullT, byte_number : Int64
  record UndefinedT, byte_number : Int64
  record BoolT, byte_number : Int64, value : Bool
  record ArrayT, byte_number : Int64, size : UInt32?
  record MapT, byte_number : Int64, size : UInt32?
  record IntT, byte_number : Int64, value : Int8 | UInt8 | Int16 | UInt16 | Int32 | UInt32 | Int64 | UInt64 | Int128
  record FloatT, byte_number : Int64, value : Float64
  record StringT, byte_number : Int64, value : String
  record BytesT, byte_number : Int64, value : Bytes
  record StringArrayStartT, byte_number : Int64
  record StringArrayEndT, byte_number : Int64
  record BytesArrayStartT, byte_number : Int64
  record BytesArrayEndT, byte_number : Int64

  alias T = NullT |
            UndefinedT |
            BoolT |
            ArrayT |
            MapT |
            IntT |
            FloatT |
            StringT |
            BytesT |
            StringArrayStartT |
            StringArrayEndT |
            BytesArrayStartT |
            BytesArrayEndT

  def self.to_diagnostic(token : T) : String
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
    when BoolT
      token.value.to_s
    when BytesArrayStartT
      "(_ "
    when BytesArrayEndT
      ")"
    when FloatT
      "TODO"
    when StringT
      "TODO"
    when StringArrayT
      "TODO"
    when MapT
      "TODO"
    when ArrayT
      "TODO"
    else
      raise "Uknown diagnostics representation for #{token.class}"
    end
  end
end
