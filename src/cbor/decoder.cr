class CBOR::Decoder
  @lexer : Lexer
  getter current_token : Token::T?

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

  def read_float
    read_type(Token::FloatT) { |token| token.value }
  end

  def read_num
    case token = @current_token
    when Token::IntT, Token::FloatT
      token.value
    else
      unexpected_token(token, "Token::IntT or Token::FloatT")
    end
  end

  def read_bytes
    read_type(Token::BytesT) { |token| token.value }
  end

  def read_tag : Tag
    read_type(Token::TagT, ignore_tag: false) { |token| token.value }
  end

  def read_bool : Bool
    read_type(Token::SimpleValueT) do |token|
      case token.value
      when SimpleValue::False
        false
      when SimpleValue::True
        true
      else
        unexpected_token(token, "SimpleValue::True or SimpleValue::False")
      end
    end
  end

  def read_nil : Nil
    read_type(Token::SimpleValueT) do |token|
      case token.value
      when SimpleValue::Null,
           SimpleValue::Undefined
        nil
      else
        unexpected_token(token, "SimpleValue::Null or SimpleValue::Undefined")
      end
    end
  end

  def consume_array(&block)
    read_type(Token::ArrayT, finish_token: false) do |token|
      read(token.size) { yield }
    end
  end

  private def finish_token!
    @current_token = @lexer.next_token
  end

  def read(size : Int32?, &block)
    if size
      size.times { yield }
    else
      @lexer.until_break do |token|
        @current_token = token
        yield
      end
    end
  end

  private macro read_type(type, finish_token = true, ignore_tag = true, &block)
    # Skip the tag unless the token we want to read is a tag
    {% if ignore_tag %}
      if @current_token.is_a?(Token::TagT)
        finish_token!
      end
    {% end %}

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
