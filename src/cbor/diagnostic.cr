require "./lexer"
require "./token"

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

    while val = next_value
      result += val
    end

    result
  end

  private def next_value : String?
    token = @lexer.next_token
    return nil unless token

    case token
    when Token::BytesArrayT
      consume_bytes_array
    else
      Token.to_diagnostic(token)
    end
  end

  private def consume_bytes_array : String
    elements = [] of String

    loop do
      token = @lexer.next_token
      raise "Unexpected EOF" unless token
      break if token.is_a?(Token::BytesArrayEndT)
      elements << Token.to_diagnostic(token)
    end

    "(_ #{elements.join(", ")})"
  end
end
