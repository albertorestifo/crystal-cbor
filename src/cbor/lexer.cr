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
    end
  end

  private def read_uint8
    byte = @io.read_byte
    return unexpect_eof if byte.nil?

    Token.new(kind: Token::Kind::UInt, value: byte)
  end

  private def unexpected_eof
    raise "Unexpected EOF"
  end
end
