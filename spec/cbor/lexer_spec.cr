require "../spec_helper"

describe CBOR::Lexer do
  describe "examples from the RFC7049 Appendix A" do
    tests = [
      {"0", "00"},
      {"1", "01"},
      {"10", "0a"},
      {"23", "17"},
      {"24", "18 18"},
      {"25", "18 19"},
      {"100", "18 64"},
      {"1000", "19 03 e8"},
      {"1000000", "1a 00 0f 42 40"},
      {"1000000000000", "1b 00 00 00 e8 d4 a5 10 00"},
      {"18446744073709551615", "1b ff ff ff ff ff ff ff ff"},
      # {"18446744073709551616", "c2 49 01 00 00 00 00 00 00 00 00"},
      {"-18446744073709551616", "3b ff ff ff ff ff ff ff ff"},
      # {"-18446744073709551617", "c3 49 01 00 00 00 00 00 00 00 00"},
      {"-1", "20"},
      {"-10", "29"},
      {"-100", "38 63"},
      {"-1000", "39 03 e7"},
    ]

    tests.each do |tt|
      debug, hex = tt
      it "Reads #{hex} as #{debug}" do
        bytes = hex.split.map(&.to_u8(16))
        lexer = CBOR::Lexer.new(Slice.new(bytes.to_unsafe, bytes.size))

        token = lexer.read_token
        CBOR::Token.to_s(token).should eq(debug)
      end
    end
  end
end
