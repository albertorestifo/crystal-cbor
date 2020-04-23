enum CBOR::Tag : UInt32
  RFC3339Time
  EpochTime
  PositiveBigNum
  NegativeBigNum
  Decimal
  BigFloat

  ConvertBase64URL = 21
  ConvertBase64
  ConvertBase16
  CBOREncoded

  URI               = 32
  Base64URL
  Base64
  RegularExpression
  MimeMessage

  CBORMarker = 55799
end
