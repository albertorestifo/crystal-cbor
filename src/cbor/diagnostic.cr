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
      # when Kind::Array
      #   value = token.value.as(Array(Type))
      #   return "[]" unless value.size > 0

      #   content = value.map { |token| to_diagnostic(token) }.join(", ")

      #   return "[#{content}]" if token.size
      #   "[_ #{content}]"
    else
      token.inspect
    end
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
