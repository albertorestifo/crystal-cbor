class CBOR::Decoder
  @lexer : Lexer
  @current_token : Token::T?

  def initialize(input)
    @lexer = Lexer.new(input)
    @current_token = @lexer.next_token
  end

  def read_string : String
    case token = @current_token
    when Token::StringT
      finish_token!
      token.value
    when Token::BytesT
      finish_token!
      String.new(token.value)
    else
      unexpected_token(token, "StringT or BytesT")
    end
  end

  def read_int
    read_type(Token::IntT) { |token| token.value }
  end

  def read_bytes
    read_type(Token::BytesT) { |token| token.value }
  end

  private def finish_token!
    @current_token = @lexer.next_token
  end

  private macro read_type(type, finish_token = true, &block)
    case token = @current_token
    when {{type}}
      {% if finish_token %}finish_token!{% end %}
      {{ block.body }}
    else
      unexpected_token(token, {{type.stringify.split("::").last}})
    end
  end

  private def unexpected_token(token, expected = nil)
    message = "Unexpected token #{token.class}"
    message += " expected #{expected}" if expected
    raise ParseError.new(message)
  end
end
