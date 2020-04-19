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
    end
  end
end
