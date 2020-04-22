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
end

alias CBOR::Token = NamedTuple(kind: Kind, value: Lexer::Type)
