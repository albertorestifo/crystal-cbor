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
    token = @lexer.read_next
    return nil unless token

    case token.kind
    when Kind::Int
      token.value.to_s
    when Kind::String
      if token.chunks
        chunks = chunks(token.value.as(String), token.chunks.as(Array(Int32)))
        "(_ #{chunks.map { |s| string(s) }.join(", ")})"
      else
        string(token.value.as(String))
      end
    when Kind::Bytes
      if token.chunks
        chunks = chunks(token.value.as(Bytes), token.chunks.as(Array(Int32)))
        "(_ #{chunks.map { |b| bytes(b) }.join(", ")})"
      else
        bytes(token.value.as(Bytes))
      end
    else
      token.kind.to_s
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
