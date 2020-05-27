class Object
  def to_cbor : Bytes
    encoder = CBOR::Encoder.new
    to_cbor(encoder)
    encoder.to_slice
  end

  def to_cbor(io : IO)
    encoder = CBOR::Encoder.new
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
    self.format(self, fraction_digits: 0).to_cbor(encoder)
  end
end

struct Time
  # Emits the time as a tagged unix timestamp, asp specified by
  # [RFC 7049 section 2.4.1](https://tools.ietf.org/html/rfc7049#section-2.4.1).
  #
  # If you would like to encode the time as a tagged RFC 3339 string isntead,
  # you can tag the field with the `Time::Format::RFC_3339` instead:
  #
  # ```
  # class Foo
  #   @[CBOR::Filed(converter: Time::Format::RFC_3339)]
  #   property created_at : Time
  # end
  # ```
  def to_cbor(encoder : CBOR::Encoder)
    encoder.write(CBOR::Tag::EpochTime)
    self.to_unix.to_cbor(encoder)
  end
end