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
    while value = next_value
      result << value
    end
    result
  end

  private def next_value : String?
    token = @lexer.read_next
    return nil unless token

    case token[:kind]
    when Kind::BytesArray
      BytesArray.new(token[:value]).to_diagnostics
    else
      Token.do_diagnostics(token)
    end
  end
end
