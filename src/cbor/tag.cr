enum CBOR::Tag : UInt32
  RFC3339Time
  EpochTime
  PositiveBigNum
  NegativeBigNum
  Decimal
  BigFloat

  COSE_Encrypt0 = 16 # COSE Single Recipient Encrypted Data Object
  COSE_Mac0     = 17 # COSE Mac w/o Recipients Object
  COSE_Sign1    = 18 # COSE Single Signer Data Object

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

  COSE_Encrypt = 96 # COSE Encrypted Data Object
  COSE_Mac     = 97 # COSE MACed Data Object
  COSE_Sign    = 98 # COSE Signed Data Object

  SelfDescribeCBOR = 55799
end
