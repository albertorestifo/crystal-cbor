require "./token"

class CBOR::Lexer
  def self.new(string : String)
    new IO::Memory.new(string)
  end

  def self.new(slice : Bytes)
    new IO::Memory.new(slice)
  end

  @token : Token::T

  def initialize(@io : IO)
    @byte_number = 0
    @current_byte_number = 0
    @token = Token::NullT.new(0)
    @token_finished = true
  end

  @[AlwaysInline]
  def current_token : Token::T
    if @token_finished
      @token_finished = false
      @token = next_token
    else
      @token
    end
  end

  @[AlwaysInline]
  def finish_token!
    @token_finished = true
  end

  @[AlwaysInline]
  def read_token : Token::T
    if @token_finished
      @token = next_token
    else
      finish_token!
    end
    @token
  end

  private def next_token
    @current_byte_number = @byte_number
    current_byte = next_byte

    case current_byte
    when 0x00..0x17
      consume_int(current_byte)
    when 0x18
      consume_int(read(UInt8))
    when 0x19
      consume_int(read(UInt16))
    when 0x1a
      consume_int(read(UInt32))
    when 0x1b
      consume_int(read(UInt64))
    when 0x20..0x37
      # This range represents values from -1..-24 so we subtract 0x20
      # from the uint8 value to
      consume_int(to_negative_int(current_byte.to_u8 - 0x20))
    when 0x38
      consume_int(to_negative_int(read(UInt8)))
    when 0x39
      consume_int(to_negative_int(read(UInt16)))
    when 0x3a
      consume_int(to_negative_int(read(UInt32)))
    when 0x3b
      consume_int(to_negative_int(read(UInt64)))
    when 0x40..0x57
      # Reads a single byte which is offset by 0x40
      Token::BytesT.new(@current_byte_number, value: Bytes[current_byte - 0x40])
    when 0x58
      consume_binary(read(UInt8))
    when 0x59
      consume_binary(read(UInt16))
    when 0x5a
      consume_binary(read(UInt32))
    when 0x5b
      consume_binary(read(UInt64))
    else
      fail
    end
  end

  private def next_byte : UInt8
    byte = @io.read_byte
    @byte_number += 1
    fail unless byte
    byte
  end

  private def consume_int(value)
    Token::IntT.new(@current_byte_number, value)
  end

  private def consume_binary(size)
    bytes = Bytes.new(size)
    @io.read_fully(bytes)
    @byte_number += size
    Token::BytesT.new(@current_byte_number, bytes)
  end

  # Creates a method overloaded for each UInt sizes to convert the UInt into
  # the respective Int capable of containing the value

  {% begin %}
    {% uints = %w(UInt8 UInt16 UInt32 UInt64) %}
    {% conv = %w(to_i8 to_i16 to_i32 to_i64 to_i128) %}

    {% for uint, index in uints %}
      # Reads the `{{uint.id}}` as a negative integer, returning the samllest
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

  private def read(type : T.class) forall T
    @byte_number += sizeof(T)
    @io.read_bytes(T, IO::ByteFormat::NetworkEndian)
  end

  private def fail
    raise "Pase error"
  end
end
