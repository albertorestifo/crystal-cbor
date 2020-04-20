abstract class CBOR::Decoder
  abstract def current_token : Token::T
  abstract def read_token : Token::T
  abstract def finish_token!

  def read : Type
    read_value
  end

  def read_value : Type
    case token = current_token
    when Token::IntT
      finish_token!
      token.value
    when Token::BytesT
      finish_token!
      token.value
    when Token::StringT
      finish_token!
      token.value
    when Token::ByteArrayT
      # Consume the array :)
    end
  end

  private def read_bytes_array_body
    read_type(Token::ByteArrayT) do |token|
    end
  end

  private macro read_type(type, finish_token = true, &block)
    case token = current_token
    when {{type}}
      {% if finish_token %}finish_token!{% end %}
      {{ block.body }}
    else
      unexpected_token(token, {{type.stringify.split("::").last}})
    end
  end

  private def unexpected_token(token, expected = nil)
    message = "Unexpected token #{Token.to_s(token)}"
    message += " expected #{expected}" if expected
    raise TypeCastError.new(message, token.byte_number)
  end
end
