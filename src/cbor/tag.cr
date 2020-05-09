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

  ExpectBase64URL = 21
  ExpectBase64
  ExpectBase16
  CBORDataItem

  URI               = 32
  Base64URL
  Base64
  RegularExpression
  MimeMessage
  UUID
  Language
  Identifier

  CBORWebToken = 61

  SelfDescribeCBOR = 55799
end
