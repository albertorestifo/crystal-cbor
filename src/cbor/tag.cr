enum CBOR::Tag : UInt32
  RFC3339Time
  EpochTime
  PositiveBigNum
  NegativeBigNum
  Decimal
  BigFloat

  CSOEEnCrypt = 16
  CSOEMac
  CSOESign

  ConvertBase64URL = 21
  ConvertBase64
  ConvertBase16
  CBOREncoded

  URI               = 32
  Base64URL
  Base64
  RegularExpression
  MimeMessage
  UUID
  Language
  Identifier

  CBORWebToken = 61

  CBORMarker = 55799
end
