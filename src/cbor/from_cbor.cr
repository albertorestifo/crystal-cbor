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

def Set.new(decoder : CBOR::Decoder)
  set = new
  decoder.consume_array { set << T.new(decoder) }
  set
end

def Hash.new(decoder : CBOR::Decoder)
  hash = new
  decoder.consume_hash do
    k = K.new(decoder)
    hash[k] = V.new(decoder)
  end
  hash
end

def Enum.new(decoder : CBOR::Decoder)
  case token = decoder.current_token
  when CBOR::Token::IntT
    decoder.finish_token!
    from_value(token.value)
  when CBOR::Token::StringT
    decoder.finish_token!
    parse(token.value)
  else
    decoder.unexpected_token(token, "IntT or StringT")
  end
end

def Tuple.new(decoder : CBOR::Decoder)
  {% begin %}
    token = decoder.current_token
    unless token.is_a?(CBOR::Token::ArrayT)
      raise decoder.unexpected_token(token, "ArrayT")
    end

    size = token.size

    raise CBOR::ParseError.new("Cannot read indefinite size array as Tuple") unless size

    unless {{ @type.size }} <= size
      raise CBOR::ParseError.new("Expected array with size #{ {{ @type.size }} }, but got #{size}")
    end
    decoder.finish_token!

    value = Tuple.new(
      {% for i in 0...@type.size %}
        (self[{{i}}].new(decoder)),
      {% end %}
    )

    value
  {% end %}
end

def NamedTuple.new(decoder : CBOR::Decoder)
  {% begin %}
    {% for key in T.keys %}
      %var{key.id} = nil
    {% end %}

    decoder.consume_hash do
      key = decoder.read_string
      case key
        {% for key, type in T %}
          when {{key.stringify}}
            %var{key.id} = {{type}}.new(decoder)
        {% end %}
      else
        raise CBOR::ParseError.new("Missing attribute: #{key}")
      end
    end

    {
      {% for key, type in T %}
        {{key}}: %var{key.id}.as({{type}}),
      {% end %}
    }
  {% end %}
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
  {% begin %}
    case decoder.current_token
    {% if T.includes? Nil %}
    when CBOR::Token::SimpleValueT
      return decoder.read_nil
    {% end %}
    {% if T.includes? Bool %}
    when CBOR::Token::BoolT
      return decoder.read_bool
    {% end %}
    {% if T.includes? String %}
    when CBOR::Token::StringT
      return decoder.read_string
    {% end %}
    when CBOR::Token::IntT
    {% type_order = [Int64, UInt64, Int32, UInt32, Int16, UInt16, Int8, UInt8, Float64, Float32] %}
    {% for type in type_order.select { |t| T.includes? t } %}
      return {{type}}.new(decoder)
    {% end %}
    when CBOR::Token::FloatT
    {% type_order = [Float64, Float32] %}
    {% for type in type_order.select { |t| T.includes? t } %}
      return {{type}}.new(decoder)
    {% end %}
    end
  {% end %}

  {% begin %}
    {% primitive_types = [Nil, Bool, String] + Number::Primitive.union_types %}
    {% non_primitives = T.reject { |t| primitive_types.includes? t } %}

    # If after traversing all the types we are left with just one
    # non-primitive type, we can parse it directly (no need to use `read_raw`)
    {% if non_primitives.size == 1 %}
      return {{non_primitives[0]}}.new(decoder)
    {% else %}
      string = pull.read_raw
      {% for type in non_primitives %}
        begin
          return {{type}}.from_json(string)
        rescue CBOR::ParseError
          # Ignore
        end
      {% end %}
      raise CBOR::ParseError.new("Couldn't parse #{self} from #{string}", *location)
    {% end %}
  {% end %}
end
