class CBOR::Token(T)
  enum Kind
    UInt8
    NInt
    Byte
    Text
    Array
    Map
    Float
  end

  def initialize(@value : T, @kind : Kind)
  end
end
