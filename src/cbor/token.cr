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

record CBOR::Token, kind : Kind, value : Lexer::Type, size : Int64? = nil
