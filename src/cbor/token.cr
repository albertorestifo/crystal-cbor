enum CBOR::Kind
  Null
  Undefined
  Bool
  Int
  Float
  Bytes
  BytesArray
  BytesArrayEnd
  String
  StringArray
  StringArrayEnd
  Array
  ArrayEnd
  Map

  def to_diagnostic : String
    case self
    when Int
      token.value.to_s
    when Bytes
      return %(h'') if token.value.empty?
      "h'#{token.value.hexstring}'"
    when Null
      "null"
    when Undefined
      "undefined"
    when BoolT
      token.value.to_s
    when BytesArray
      "(_ "
    when BytesArrayEnd
      ")"
    when Float
      "TODO"
    when String
      "TODO"
    when StringArray
      "TODO"
    when Map
      "TODO"
    when Array
      "TODO"
    else
      raise "Uknown diagnostics representation for #{self.to_s}"
    end
  end
end

alias CBOR::Token = NamedTuple(kind: Kind, value: Type)
