require "uuid"

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

def Int128.new(decoder : CBOR::Decoder)
  decoder.read_int.to_i128
end

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
    raise CBOR::ParseError.new("Expected tag to have value 0 or 1, got #{tag.value}")
  end
end

# Reads the CBOR value as a BigInt.
# If the next token is an integer, then the integer will be transformed as a
# BigInt, otherwhise the value must be surrounded by a tag with value 2
# (positive) or 3 (negative).
def BigInt.new(decoder : CBOR::Decoder)
  case token = decoder.current_token
  when CBOR::Token::TagT
    decoder.finish_token!

    tag = token.value
    unless tag == CBOR::Tag::PositiveBigNum || tag == CBOR::Tag::NegativeBigNum
      raise CBOR::ParseError.new("Expected tag to have value 2 or 3, got #{tag.value}")
    end

    big = new(decoder.read_bytes.hexstring, 16)

    if tag == CBOR::Tag::NegativeBigNum
      big *= -1
      big -= 1
    end

    big
  when CBOR::Token::IntT
    decoder.finish_token!
    new(token.value)
  else
    decoder.unexpected_token(token, "IntT or TagT")
  end
end

# Reads the CBOR value as a BigDecimal.
# If the next token is a float, then it'll be transformed to a BigDecimal,
# otherwhise the value must be correctly tagged with value 4 (decimal fraction)
# or 5 (big float).
def BigDecimal.new(decoder : CBOR::Decoder)
  case token = decoder.current_token
  when CBOR::Token::TagT
    decoder.finish_token!

    tag = token.value
    unless tag == CBOR::Tag::Decimal || tag == CBOR::Tag::BigFloat
      raise CBOR::ParseError.new("Expected tag to have value 4 or 5, got #{tag.value}")
    end

    exponent, matissa = Tuple(Int128, BigInt).new(decoder)

    base = tag == CBOR::Tag::Decimal ? 10.0 : 2.0
    e = base**exponent
    new(matissa) * new(e)
  when CBOR::Token::FloatT
    new(token.value)
  else
    decoder.unexpected_token(token, "FloatT or TagT")
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
    when CBOR::Token::SimpleValueT
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
    else
      # This case check is non-exhaustive on purpose
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
      {% for type in non_primitives %}
        begin
          return {{type}}.new(decoder)
        rescue CBOR::ParseError
          # Ignore
        end
      {% end %}
      raise CBOR::ParseError.new("Couldn't parse #{self}")
    {% end %}
  {% end %}
end

struct UUID
  # Creates UUID from CBOR using `CBOR::Decoder`.
  #
  # ```
  # require "cbor"
  #
  # class Example
  #   include CBOR::Serializable
  #
  #   property id : UUID
  # end
  #
  # hash = {"id" => "ba714f86-cac6-42c7-8956-bcf5105e1b81"}
  # example = Example.from_cbor hash.to_cbor
  # example.id # => UUID(ba714f86-cac6-42c7-8956-bcf5105e1b81)
  # ```
  def self.new(pull : CBOR::Decoder)
    # Either the UUID was encoded as String or bytes (smaller).
    case pull.current_token
    when CBOR::Token::StringT
      new(pull.read_string)
    when CBOR::Token::BytesT
      new(pull.read_bytes)
    else
      raise "trying to get an UUID, but CBOR value isn't a string nor bytes: #{pull.current_token}"
    end
  end
end
