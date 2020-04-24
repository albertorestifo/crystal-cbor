def Object.from_cbor(string_or_io)
  parser = CBOR::Decoder.new(string_or_io)
  new(parser)
end

def String.new(decoder : CBOR::Decoder)
  decoder.read_string
end

{% for size in [8, 16, 32, 64] %}

  def Int{{size.id}}.new(decoder : CBOR::Decoder)
    decoder.read_int.to_i{{size.id}}
  end

  def UInt{{size.id}}.new(decoder : CBOR::Decoder)
    decoder.read_int.to_u{{size.id}}
  end

{% end %}

def Bool.new(decoder : CBOR::Decoder)
  decoder.read_bool
end

def Slice.new(decoder : CBOR::Decoder)
  decoder.read_bytes.to_slice
end

# Reads the CBOR values a time. The value must be surrounded by a time tag as
# specified by [Section 2.4.1 of RFC 7049][1].
#
# [1]: https://tools.ietf.org/html/rfc7049#section-2.4.1
def Time.new(decoder : CBOR::Decoder)
  case tag = decoder.read_tag
  when CBOR::Tag::RFC3339Time
    Time::Format::RFC_3339.parse(decoder.read_string)
  when CBOR::Tag::EpochTime
    case num = decoder.read_num
    when Int
      Time.unix(num)
    when Float
      Time.unix_ms((BigFloat.new(num) * 1_000).to_u64)
    end
  else
    raise CBOR::ParseError.new("Expected tag to have value 0 or 1, got #{tag.value.to_s}")
  end
end
