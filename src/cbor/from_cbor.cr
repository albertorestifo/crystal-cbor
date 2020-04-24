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

{% for size in [32, 64] %}

  def Float{{size.id}}.new(decoder : CBOR::Decoder)
    decoder.read_float.to_f{{size.id}}
  end

{% end %}

def Bool.new(decoder : CBOR::Decoder)
  decoder.read_bool
end

def Nil.new(decoder : CBOR::Decoder)
  decoder.read_nil
end

def Slice.new(decoder : CBOR::Decoder)
  decoder.read_bytes.to_slice
end

def Array.new(decoder : CBOR::Decoder)
  arr = new
  decoder.consume_array { arr << T.new(decoder) }
  arr
end

# Reads the CBOR values as a time. The value must be surrounded by a time tag as
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

def Union.new(decoder : CBOR::Decoder)
  token = decoder.current_token

  # Optimization: use fast path for primitive types
  {% begin %}
    # Here we store types that are not primitive types
    {% non_primitives = [] of Nil %}

    {% for type, index in T %}
      {% if type == Nil %}
        return decoder.read_nil if token.is_a?(CBOR::Token::SimpleValueT)
      {% elsif type == Bool %}
        return decoder.read_bool if token.is_a?(CBOR::Token::SimpleValueT)
      {% elsif type == String %}
        return decoder.read_string if token.is_a?(CBOR::Token::StringT)
      {% elsif type == Int8 || type == Int16 || type == Int32 || type == Int64 ||
                 type == UInt8 || type == UInt16 || type == UInt32 || type == UInt64 %}
        return {{type}}.new(decoder) if token.is_a?(CBOR::Token::IntT)
      {% elsif type == Float32 || type == Float64 %}
        return {{type}}.new(decoder) if token.is_a?(CBOR::Token::FloatT)
        {% unless T.any? { |t| t < Int } %}
          return {{type}}.new(decoder) if token.is_a?(CBOR::Token::IntT)
        {% end %}
      {% else %}
        {% non_primitives << type %}
      {% end %}
    {% end %}

    # If after traversing all the types we are left with just one
    # non-primitive type, we can parse it directly (no need to use `read_raw`)
    {% if non_primitives.size == 1 %}
      return {{non_primitives[0]}}.new(decoder)
    {% else %}
      raise "What is this?"
    #   node = decoder.read_node
    #   {% for type in non_primitives %}
    #     unpacker = CBOR::NodeUnpacker.new(node)
    #     begin
    #       return {{type}}.new(unpacker)
    #     rescue e : CBOR::TypeCastError
    #       # ignore
    #     end
    #   {% end %}
    # {% end %}
  {% end %}

  raise CBOR::ParseError.new("Couldn't parse data as " + {{T.stringify}})
end
