require "./lexer"
require "./token"

# Reads a CBOR input into a diagnostic string.
# This consumes the IO and is mostly usedful to tests again the example
# provided in the RFC and ensuring a correct functioning of the `CBOR::Lexer`.
class CBOR::Diagnostic
  @lexer : Lexer
  @is_array : Bool = false

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
    when Token::BytesArray
      @is_array = true
    when Token::BreakT
      @is_array = flase
    end

    separator + Token.to_diagnostic(token)
  end

  private def separator : String
    return ", " if @is_array
    ""
  end
end
