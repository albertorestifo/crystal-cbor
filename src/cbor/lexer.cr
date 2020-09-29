class CBOR::Lexer
  def self.new(slice : Bytes)
    new IO::Memory.new(slice)
  end

  @eof : Bool = false

  def initialize(@io : IO)
  end

  def next_token : Token::T?
    return nil if @eof

    byte = next_byte
    return nil unless byte

    decode(byte)
  end

  # Read the next pair of tokens, useful for maps.
  # Raises an exception if there are no two pairs left.
  def next_pair : Tuple(Token::T, Token::T)
    pairs = Array(Token::T).new(2) do
      token = next_token
      raise ParseError.new("Unexpected EOF while reading next pair") unless token
      token
    end
    Tuple.new(pairs[0], pairs[1])
  end

  private def decode(byte : UInt8) : Token::T
    case byte
    when 0x00..0x1b
      consume_int(read_size(byte))
    when 0x20..0x3b
      consume_int(to_negative_int(read_size(byte - 0x20)))
    when 0x40..0x5b
      consume_binary(read_size(byte - 0x40))
    when 0x5f
      read_bytes_array
    when 0x60..0x7b
      consume_string(read_size(byte - 0x60))
    when 0x7f
      read_string_array
    when 0x80..0x9b
      array_start(read_size(byte - 0x80))
    when 0x9f
      Token::ArrayT.new
    when 0xa0..0xbb
      map_start(read_size(byte - 0xa0))
    when 0xbf
      Token::MapT.new
    when 0xc0..0xdb
      consume_tag(read_size(byte - 0xc0))
    when 0xe0..0xf8
      consume_simple_value(read_size(byte - 0xe0))
    when 0xf9
      Token::FloatT.new(value: Float32.new(read(UInt16)))
    when 0xfa
      Token::FloatT.new(value: read(Float32))
    when 0xfb
      Token::FloatT.new(value: read(Float64))
    when 0xff
      Token::BreakT.new
    else
      raise ParseError.new("Unexpected byte 0x#{byte.to_s(16)}")
    end
  end

  private def read_bytes_array : Token::BytesT
    bytes = BytesArray.new
    chunks = Array(Int32).new

    until_break do |token|
      unless token.is_a?(Token::BytesT)
        raise ParseError.new("Invalid token #{token.class} while parsing a bytes array")
      end

      chunks << token.value.size
      bytes << token.value
    end

    Token::BytesT.new(value: bytes.to_bytes, chunks: chunks)
  end

  private def read_string_array : Token::StringT
    value = ""
    chunks = Array(Int32).new

    until_break do |token|
      unless token.is_a?(Token::StringT)
        raise ParseError.new("Invalid token #{token.class} while parsing a string array")
      end

      chunks << token.value.size
      value += token.value
    end

    Token::StringT.new(value: value, chunks: chunks)
  end

  private def until_break(&block : Token::T ->)
    loop do
      token = next_token
      raise ParseError.new("Unexpected EOF while searching for 0xff (break)") unless token
      break if token.is_a?(Token::BreakT)

      yield token
    end
  end

  # Reads the size for the next token type
  private def read_size(current_byte : UInt8) : Int
    case current_byte
    when 0x00..0x17
      current_byte
    when 0x18
      read(UInt8)
    when 0x19
      read(UInt16)
    when 0x1a
      read(UInt32)
    when 0x1b
      read(UInt64)
    else
      raise ParseError.new("Unexpected byte 0x#{current_byte.to_s(16)} while reading size")
    end
  end

  private def next_byte : UInt8?
    byte = @io.read_byte
    return byte if byte

    @eof = true
    nil
  end

  private def consume_int(value)
    Token::IntT.new(value: value)
  end

  private def consume_binary(size : Int)
    bytes = read_bytes(size)
    Token::BytesT.new(value: bytes)
  end

  private def consume_string(size)
    Token::StringT.new(value: @io.read_string(size))
  end

  private def array_start(size)
    raise ParseError.new("Maximum size for array exeeded") if size > Int32::MAX
    Token::ArrayT.new(size: size.to_i32)
  end

  private def map_start(size)
    raise ParseError.new("Maximum size for array exeeded") if size > Int32::MAX
    Token::MapT.new(size: size.to_i32)
  end

  private def consume_tag(id) : Token::TagT
    raise ParseError.new("Maximum size for tag ID exceeded") if id > UInt32::MAX
    Token::TagT.new(value: Tag.new(id.to_u32))
  end

  private def consume_simple_value(id) : Token::SimpleValueT
    raise ParseError.new("Invalid simple value #{id}") if id > 255
    Token::SimpleValueT.new(value: SimpleValue.new(id.to_u8))
  end

  # Creates a method overloaded for each UInt sizes to convert the UInt into
  # the respective Int capable of containing the value

  {% begin %}
    {% uints = %w(UInt8 UInt16 UInt32 UInt64) %}
    {% conv = %w(to_i8 to_i16 to_i32 to_i64 to_i128) %}

    {% for uint, index in uints %}
      # Reads the `{{uint.id}}` as a negative integer, returning the smallest
      # integer capable of containing the value.
      def to_negative_int(value : {{uint.id}})
        int = begin
                -value.{{conv[index].id}}
              rescue OverflowError
                -value.{{conv[index + 1].id}}
              end

        int - 1
      end
    {% end %}
  {% end %}

  private def read_bytes(size)
    bytes = Bytes.new(size)
    @io.read_fully(bytes)
    bytes
  end

  private def read(type : T.class) forall T
    @io.read_bytes(T, IO::ByteFormat::NetworkEndian)
  end
end
