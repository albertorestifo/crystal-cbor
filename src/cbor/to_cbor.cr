require "uuid"

class Object
  def to_cbor : Bytes
    encoder = CBOR::Encoder.new
    to_cbor(encoder)
    encoder.to_slice
  end

  def to_cbor(io : IO)
    encoder = CBOR::Encoder.new(io)
    to_cbor(encoder)
    self
  end

  def to_cbor(encoder : CBOR::Encoder)
    encoder.write(self)
  end
end

struct Set
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write_array_start(self.size)
    each { |elem| elem.to_cbor(encoder) }
  end
end

class Array
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write_array_start(self.size)
    each { |elem| elem.to_cbor(encoder) }
  end
end

class Hash
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write_object_start(self.size)
    each do |key, value|
      key.to_cbor(encoder)
      value.to_cbor(encoder)
    end
  end
end

struct Tuple
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write_array_start(self.size)
    each { |elem| elem.to_cbor(encoder) }
  end
end

struct NamedTuple
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write_object_start(self.size)
    {% for key in T.keys %}
      {{key.stringify}}.to_cbor(encoder)
      self[{{key.symbolize}}].to_cbor(encoder)
    {% end %}
  end
end

struct Enum
  def to_cbor(encoder : CBOR::Encoder)
    value.to_cbor(encoder)
  end
end

struct Time::Format
  def to_cbor(value : Time, encoder : CBOR::Encoder)
    format(value).to_cbor(encoder)
  end
end

module Time::Format::RFC_3339
  # Encodes the time as a properly tagged CBOR string as specified by
  # [RFC 7049 section 2.4.1](https://tools.ietf.org/html/rfc7049#section-2.4.1).
  def self.to_cbor(value : Time, encoder : CBOR::Encoder)
    encoder.write(CBOR::Tag::RFC3339Time)
    format(value, fraction_digits: 0).to_cbor(encoder)
  end
end

module Time::EpochConverter
  # Emits the time as a tagged unix timestamp, as specified by
  # [RFC 7049 section 2.4.1](https://tools.ietf.org/html/rfc7049#section-2.4.1).
  #
  def self.to_cbor(value : Time, encoder : CBOR::Encoder)
    encoder.write(CBOR::Tag::EpochTime)
    value.to_unix.to_cbor(encoder)
  end
end

struct Time
  # Encodes the time as a properly tagged CBOR string as specified by
  # [RFC 7049 section 2.4.1](https://tools.ietf.org/html/rfc7049#section-2.4.1).
  #
  # If you would like to encode it as a unix timestamp, you can instead specify
  # `Time::EpochConverter`:
  #
  # ```
  # class Foo
  #   @[CBOR::Filed(converter: Time::EpochConverter)]
  #   property created_at : Time
  # end
  # ```
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write(CBOR::Tag::RFC3339Time)
    encoder.write(to_rfc3339)
  end
end

# struct BigInt
#   # Encodes the value a bytes array tagged with the CBOR tag 2 or 3, as specified
#   # in [RFC 7049 Section 2.4.2](https://tools.ietf.org/html/rfc7049#section-2.4.2).
#   def to_cbor(encoder : CBOR::Encoder)
#     encoded_value = BigInt.new(self)
#     if encoded_value >= 0
#       encoder.write(CBOR::Tag::PositiveBigNum)
#     else
#       encoder.write(CBOR::Tag::NegativeBigNum)
#       encoded_value *= -1
#       encoded_value += 1
#     end

#     io = IO::Memory.new
#     encoded_value.to_io(io, IO::ByteFormat::NetworkEndian)
#     encoder.write(io.to_slice)
#   end
# end

# struct BigDecimal
#   def to_cbor(encoder : CBOR::Encoder)
#   end
# end

struct UUID
  # Returns UUID as CBOR value.
  #
  # ```
  # uuid = UUID.new("87b3042b-9b9a-41b7-8b15-a93d3f17025e")
  # uuid.to_cbor
  # ```
  def to_cbor(cbor : CBOR::Encoder)
    cbor.write(@bytes.to_slice)
  end
end
