module CBOR::Tag
  enum Kind
    Unassigned
    RFC3339Time
    EpochTime
    PositiveBigNum
    NegativeBigNum
    DecimalFraction
    BigFloat
    ExpectBase64URLConversion
    ExpectBase64Conversion
    ExpectBase16Conversion
    EncodedCBOR
    URI
    Base64URL
    Base64
    RegularExpresion
    MIME
    SelfDescribeCBOR
  end
end
