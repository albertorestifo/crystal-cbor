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

record CBOR::Token,
  kind : Kind,
  value : Type,
  size : Int32? = nil,
  # Used only for BytesArray and StringArray: it contains the size of each
  # chunks composing the type
  chunks : Array(Int32)? = nil
