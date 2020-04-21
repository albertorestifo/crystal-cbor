require "../spec_helper"

describe CBOR::BytesArray do
  describe "#to_bytes" do
    it "converts to bytes" do
      arr = CBOR::BytesArray.new
      arr << Bytes[0xff, 0xff]
      arr << Bytes[0xee, 0xee]

      bytes = arr.to_bytes
      bytes.size.should eq(4)
      bytes.should eq(Bytes[0xff, 0xff, 0xee, 0xee])
    end

    it "can be called more than ocne" do
      arr = CBOR::BytesArray.new
      arr << Bytes[0xff, 0xff]
      arr << Bytes[0xee, 0xee]

      bytes1 = arr.to_bytes
      bytes1.size.should eq(4)
      bytes1.should eq(Bytes[0xff, 0xff, 0xee, 0xee])

      bytes2 = arr.to_bytes
      bytes2.size.should eq(4)
      bytes2.should eq(Bytes[0xff, 0xff, 0xee, 0xee])
    end
  end
end
