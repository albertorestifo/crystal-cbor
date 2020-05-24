require "../spec_helper"

class ExampleA
  include CBOR::Serializable

  property a : Int32
  property b : Array(Int32)
end

class ExampleB
  include CBOR::Serializable

  @[CBOR::Field(key: "Fun")]
  property is_fun : Bool

  @[CBOR::Field(key: "Amt")]
  property amt : Int32
end

class ExampleC
  include CBOR::Serializable

  property b : String
end

class ExampleStrict
  include CBOR::Serializable

  property a : Int32
end

class ExampleUnmapped
  include CBOR::Serializable
  include CBOR::Serializable::Unmapped

  property a : Int32
end

describe CBOR::Serializable do
  describe "rfc examples" do
    describe %(example {_ "a": 1, "b": [_ 2, 3]}) do
      it "decodes from cbor" do
        result = ExampleA.from_cbor(Bytes[0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff])

        result.a.should eq(1)
        result.b.should eq([2, 3])
      end
    end

    describe %(example {_ "Fun": true, "Amt": -2}) do
      it "decodes from cbor" do
        result = ExampleB.from_cbor(Bytes[0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff])

        result.is_fun.should be_true
        result.amt.should eq(-2)
      end
    end

    describe %(example ["a", {_ "b": "c"}]) do
      it "decodes from cbor" do
        result = Array(String | ExampleC).from_cbor(Bytes[0x82, 0x61, 0x61, 0xbf, 0x61, 0x62, 0x61, 0x63, 0xff])

        result.size.should eq(2)

        result[0].as(String).should eq("a")
        result[1].as(ExampleC).b.should eq("c")
      end
    end
  end

  describe "strict by default" do
    it "errors on missing fields" do
      expect_raises(CBOR::ParseError) do
        ExampleStrict.from_cbor(Bytes[0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff])
      end
    end
  end

  describe CBOR::Serializable::Unmapped do
    it "adds missing fields to the map" do
      result = ExampleUnmapped.from_cbor(Bytes[0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff])

      result.a.should eq(1)
      result.cbor_unmapped.should eq({"b" => [2, 3]})
    end
  end
end
