require "./token"

class CBOR::Lexer
  BREAK = 0xff

  def self.new(string : String)
    new IO::Memory.new(string)
  end

  def self.new(slice : Bytes)
    new IO::Memory.new(slice)
  end

  @token : Token::T
  @current_pos : Int64
  @token_finished : Bool

  def initialize(@io : IO)
    @current_pos = 0
    @token = Token::UndefinedT.new(0)
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
    @current_pos = @io.pos.to_i64
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
      # read current_byte - 0x40 bytes ahead
      consume_binary(current_byte - 0x40)
    when 0x58
      consume_binary(read(UInt8))
    when 0x59
      consume_binary(read(UInt16))
    when 0x5a
      consume_binary(read(UInt32))
    when 0x5b
      consume_binary(read(UInt64))
    when 0x5f
      Token::BytesArrayT.new(@current_pos)
    else
      raise ParseError.new("Unexpected first byte #{current_byte}")
    end
  end

  private def next_byte : UInt8
    byte = @io.read_byte
    raise ParseError.new("Unexpected EOF at byte #{@io.pos}") unless byte
    byte
  end

  private def consume_int(value)
    Token::IntT.new(@current_pos, value)
  end

  private def consume_binary(size)
    bytes = Bytes.new(size)
    @io.read_fully(bytes)
    Token::BytesT.new(@current_pos, bytes)
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
    @io.read_bytes(T, IO::ByteFormat::NetworkEndian)
  end
end
