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
      consume_int(read(Uint8))
    when 0x19
      consume_int(read(Uint16))
    when 0x1a
      consume_int(read(Uint32))
    when 0x1b
      consume_int(read(Uint64))
    when 0x20..0x37
      consume_int(flip(current_byte.to_i8))
    when 0x38
      consume_int(flip(read(Uint8).to_i8))
    when 0x39
      consume_int(flip(read(Uint16).to_i16))
    when 0x3a
      consume_int(flip(read(Uint32).to_i32))
    when 0x3b
      consume_int(flip(read(Uint64).to_i64))
    end
  end

  private def next_byte : Uint8
    byte = @io.read_byte
    @byte_number += 1
    fail unless byte
    byte
  end

  private def consume_int(value)
    Token::IntT.new(@current_byte_number, value)
  end

  private def flip(value)
    -1 - value
  end

  private def read(type : T.class) forall T
    @byte_number += sizeof(T)
    @io.read_bytes(T, IO::ByteFormat::NetworkEndian)
  end

  private def fail
    raise "Pase error"
  end
end
