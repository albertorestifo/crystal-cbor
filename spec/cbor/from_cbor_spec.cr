require "../spec_helper"

describe "CBOR helpers on basic types" do
  describe "#from_cbor" do
    tests = [
      {String, Bytes[0x61, 0x61], "a"},
      {UInt8, Bytes[0x18, 0x18], 24},
      {UInt16, Bytes[0x19, 0x03, 0xe8], 1000},
      {UInt32, Bytes[0x1a, 0x00, 0x0f, 0x42, 0x40], 1000000},
      {UInt64, Bytes[0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00], 1000000000000},
      {Int8, Bytes[0x29], -10},
      {Bytes, Bytes[0x44, 0x01, 0x02, 0x03, 0x04], Bytes[0x01, 0x02, 0x03, 0x04]},
    ]

    tests.each do |tt|
      type, bytes, want = tt

      it "decodes #{type.class}" do
        res = type.from_cbor(bytes)
        res.should eq(want)
      end
    end
  end
end
