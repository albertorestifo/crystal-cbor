require "../spec_helper"

describe CBOR::Lexer do
  describe "examples from the RFC7049 Appendix A" do
    tests : Array(Tuple(String, Bytes)) = [
      {"0", [0x00]},
      {"1", [0x01]},
      # {"10", "0a"},
      # {"23", "17"},
      # {"24", "18 18"},
      # {"25", "18 19"},
      # {"100", "18 64"},
      # {"1000", "19 03 e8"},
      # {"1000000", "1a 00 0f 42 40"},
      # {"1000000000000", "1b 00 00 00 e8 d4 a5 10 00"},
      # {"18446744073709551615", "1b ff ff ff ff ff ff ff ff"},
      # {"18446744073709551616", "c2 49 01 00 00 00 00 00 00 0000"},
      # {"-18446744073709551616", "3b ff ff ff ff ff ff ff ff"},
      # {"-18446744073709551617", "c3 49 01 00 00 00 00 00 00 00 00"},
      # {"-1", "20"},
      # {"-10", "29"},
      # {"-100", "38 63"},
      # {"-1000", "39 03 e7"},
    ]

    tests.each do |tt|
      it "Reads #{tt[1].inspect} as #{tt[0]}" do
        lexer = CBOR::Lexer.new(tt[1])

        token = lexer.read_token
        CBOR::Token.to_s(token).should eq(tt[0])
      end
    end
  end
end
