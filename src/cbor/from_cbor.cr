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

def Slice.new(decoder : CBOR::Decoder)
  decoder.read_bytes.to_slice
end
