class CBOR::Decoder
  @lexer : Lexer
  getter current_token : Token::T?

  def initialize(input)
    @lexer = Lexer.new(input)
    @current_token = @lexer.next_token
  end

  def read_value : Type
    case token = @current_token
    when Token::TagT
      finish_token!
      read_value
    when Token::StringT
      finish_token!
      token.value
    when Token::IntT
      finish_token!
      token.value
    when Token::FloatT
      finish_token!
      token.value
    when Token::BytesT
      finish_token!
      token.value
    when Token::SimpleValueT
      finish_token!
      token.value.to_t
    when Token::ArrayT
      finish_token!
      arr = Array(Type).new
      consume_sequence(token.size) { arr << read_value }
      arr
    when Token::MapT
      finish_token!
      map = Hash(Type, Type).new
      consume_sequence(token.size) { map[read_value] = read_value }
      map
    else
      unexpected_token(token)
    end
  end

  def read_string : String
    case token = @current_token
    when Token::StringT
      finish_token!
      token.value
    when Token::BytesT
      finish_token!
      String.new(token.value)
    when Token::IntT
      finish_token!
      token.value.to_s
    else
      unexpected_token(token, "StringT, BytesT or IntT")
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
      return nil if token.value.is_nil?

      unexpected_token(token, "SimpleValue::Null or SimpleValue::Undefined")
    end
  end

  def read_nil_or
    token = @current_token
    if token.is_a?(Token::SimpleValueT) && token.value.is_nil?
      finish_token!
      nil
    else
      yield
    end
  end

  def consume_array(&block)
    read_type(Token::ArrayT) do |token|
      consume_sequence(token.size) { yield }
    end
  end

  def read_begin_hash
    read_type(Token::MapT, finish_token: false) { |token| }
  end

  def consume_hash(&block)
    read_type(Token::MapT) do |token|
      consume_sequence(token.size) { yield }
    end
  end

  def finish_token!
    @current_token = @lexer.next_token
  end

  private def consume_sequence(size : Int32?, &block)
    if size
      size.times { yield }
    else
      until @current_token.is_a?(Token::BreakT)
        yield
      end
    end
  end

  private macro read_type(type, finish_token = true, ignore_tag = true, &block)
    begin
      # Skip the tag unless the token we want to read is a tag
      {% if ignore_tag %}
        if @current_token.is_a?(Token::TagT)
          finish_token!
        end
      {% end %}

      case token = @current_token
      when {{type}}
        {% if finish_token %}
          finish_token!
        {% end %}
        {{ block.body }}
      else
        unexpected_token(token, {{type.stringify.split("::").last}})
      end
    rescue err
      raise CBOR::ParseError.new("{{type}} -> #{err}")
    end
  end

  def unexpected_token(token, expected = nil)
    message = "Unexpected token #{token.class}"
    message += " expected #{expected}" if expected
    raise ParseError.new(message)
  end
end
