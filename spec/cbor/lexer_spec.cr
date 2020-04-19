require "../spec_helper"

describe CBOR::Lexer do
  describe "read_token" do
    describe "reads an int" do
      tests = [
        {value: 0, bytes: Bytes[0x00]},
        {value: 1, bytes: Bytes[0x01]},
        {value: 10, bytes: Bytes[0x0a]},
        {value: 23, bytes: Bytes[0x17]},
        {value: 24, bytes: Bytes[0x18, 0x18]},
        {value: 25, bytes: Bytes[0x18, 0x19]},
        {value: 100, bytes: Bytes[0x18, 0x64]},
        {value: 1000, bytes: Bytes[0x19, 0x03, 0xe8]},
        {value: 1000000, bytes: Bytes[0x1a, 0x00, 0x0f, 0x42, 0x40]},
        {value: 1000000000000, bytes: Bytes[0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]},
        {value: -1, bytes: Bytes[0x20]},
        {value: -10, bytes: Bytes[0x29]},
        {value: -100, bytes: Bytes[0x38, 0x63]},
        {value: -1000, bytes: Bytes[0x39, 0x03, 0xe7]},
      ]

      tests.each do |tt|
        it "reads #{tt[:bytes].hexstring} as #{tt[:value].to_s}" do
          lexer = CBOR::Lexer.new(tt[:bytes])

          token = lexer.read_token
          token.should be_a(CBOR::Token::IntT)
          token.as(CBOR::Token::IntT).value.should eq(tt[:value])
        end
      end
    end
  end
end
