# Reads a CBOR input into a diagnostic string.
# This consumes the IO and is mostly usedful to tests again the example
# provided in the RFC and ensuring a correct functioning of the `CBOR::Lexer`.
class CBOR::Diagnostic
  @lexer : Lexer

  def initialize(input)
    @lexer = Lexer.new(input)
  end

  # Reads the content of the IO and prints out a diagnostic string
  # represation of the input.
  def to_s : String
    result = ""
    while value = next_value
      result += value
    end
    result
  end

  private def next_value : String?
    token = @lexer.next_token
    return nil unless token
    to_diagnostic(token)
  end

  private def to_diagnostic(token : Token::T) : String
    case token
    when Token::IntT
      token.value.to_s
    when Token::StringT
      if token.chunks
        chunks = chunks(token.value, token.chunks.not_nil!)
        "(_ #{chunks.map { |s| string(s) }.join(", ")})"
      else
        string(token.value)
      end
    when Token::BytesT
      if token.chunks
        chunks = chunks(token.value, token.chunks.not_nil!)
        "(_ #{chunks.map { |b| bytes(b) }.join(", ")})"
      else
        bytes(token.value)
      end
    when Token::ArrayT
      arr = read_array(token.size)
      return "[#{arr.join(", ")}]" if token.size
      "[_ #{arr.join(", ")}]"
    when Token::MapT
      hash_body = read_hash(token.size).join(", ")
      return "{#{hash_body}}" if token.size
      "{_ #{hash_body}}"
    when Token::SimpleValueT
      token.value.to_diagnostic
    when Token::TagT
      case token.value
      when Tag::PositiveBigNum
        read_big_int
      when Tag::NegativeBigNum
        read_big_int(negative: true)
      else
        "#{token.value.value.to_s}(#{next_value})"
      end
    when Token::FloatT
      return "NaN" if token.value.nan?
      return token.value.to_s if token.value.finite?

      case value = token.value
      when Float32
        return "Infinity" if value == Float32::INFINITY
        "-Infinity"
      when Float64
        return "Infinity" if value == Float64::INFINITY
        "-Infinity"
      else
        token.value.to_s
      end
    else
      token.inspect
    end
  end

  private def read_array(size : Int32?) : Array(String)
    arr = size ? Array(String).new(size) : Array(String).new

    if size
      size.times do
        val = next_value
        raise ParseError.new("Unexpected EOF while reading array body") unless val
        arr << val
      end
    else
      @lexer.until_break { |token| arr << to_diagnostic(token) }
    end

    arr
  end

  # Reads the hash, returning an array of key-pairs strings already
  # correctly formatted in the diagnostic notation
  private def read_hash(size : Int32?) : Array(String)
    key_pairs = Array(String).new

    if size
      size.times { key_pairs << key_value(*@lexer.next_pair) }
    else
      @lexer.pairs_until_break { |pairs| key_pairs << key_value(*pairs) }
    end

    key_pairs
  end

  private def read_big_int(negative : Bool = false) : String
    token = @lexer.next_token
    raise ParseError.new("Unexpected EOF after tag") unless token
    raise ParseError.new("Unexpected type #{token.class}, want Token::BytesT") unless token.is_a?(Token::BytesT)

    big = BigInt.new(token.value.hexstring, 16)
    if negative
      big *= -1
      big -= 1
    end

    big.to_s
  end

  private def key_value(key : Token::T, value : Token::T) : String
    "#{to_diagnostic(key)}: #{to_diagnostic(value)}"
  end

  private def chunks(value : Bytes, chunks : Array(Int32)) : Array(Bytes)
    res = Array(Bytes).new
    bytes = value.to_a
    chunks.each do |size|
      bytes_chunk = bytes.shift(size)
      res << Bytes.new(bytes_chunk.to_unsafe, bytes_chunk.size)
    end
    res
  end

  private def chunks(value : String, chunks : Array(Int32)) : Array(String)
    res = Array(String).new
    arr = value.split("")
    chunks.each do |size|
      res << arr.shift(size).join
    end
    res
  end

  private def bytes(b : Bytes) : String
    "h'#{b.hexstring}'"
  end

  private def string(s : String) : String
    %("#{s}")
  end
end
