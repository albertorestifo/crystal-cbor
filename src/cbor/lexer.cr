require "./token"

class CBOR::Lexer
  @current_byte : UInt8

  def initialize(@io : IO)
    @current_byte = 0x0
  end

  def next_token : Token?
    byte = @io.read_byte
    return nil if byte.nil?

    @current_byte = byte

    # See: RFC7049 Appedix B
    case @current_byte
    when .<= 0x17
      Token.new(kind: Token::Kind::UInt, value: @curren_byte)
    when 0x18
      read_uint8
    when 0x19
      read_uint16
    when 0x1a
      read_uint32
    when 0x1b
      read_uint64
    when .<= 0x37
      Token.new(kind: Token::Kind::NInt, value: Int8(@curren_byte))
    end
  end

  private def read_uint8
    byte = @io.read_byte
    return unexpect_eof if byte.nil?

    Token.new(kind: Token::Kind::UInt, value: byte)
  end

  private def read_uint16
    value = UInt16.from_io(read_next(2), IO::ByteFormat::BigEndian)
    Token.new(kind: Token::Kind::UInt, value: value)
  end

  private def read_uint32
    value = UInt32.from_io(read_next(4), IO::ByteFormat::BigEndian)
    Token.new(kind: Token::Kind::UInt, value: value)
  end

  private def read_uint64
    value = UInt64.from_io(read_next(8), IO::ByteFormat::BigEndian)
    Token.new(kind: Token::Kind::UInt, value: value)
  end

  private def read_next(n : Int)
    slice = Bytes.new(n)

    read = @io.read(slice)
    return unexpect_eof if read == 0

    slice
  end

  private def unexpected_eof
    raise "Unexpected EOF"
  end
end
