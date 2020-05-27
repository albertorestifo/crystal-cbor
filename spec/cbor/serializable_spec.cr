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

class Location
  include CBOR::Serializable

  @[CBOR::Field(key: "lat")]
  property latitude : Float64

  @[CBOR::Field(key: "lng")]
  property longitude : Float64

  def initialize(@latitude, @longitude)
  end
end

class House
  include CBOR::Serializable
  property address : String
  property location : Location?

  def initialize(@address, @location)
  end
end

struct A
  include CBOR::Serializable
  @a : Int32
  @b : Float64 = 1.0
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

  describe "documentation examples" do
    describe "house example" do
      houses = [House.new(address: "Crystal Road 1234", location: Location.new(latitude: 12.3, longitude: 34.5))]
      cbor_houses_bytes = Bytes[129, 191, 103, 97, 100, 100, 114, 101, 115, 115, 113, 67, 114, 121, 115, 116, 97, 108, 32, 82, 111, 97, 100, 32, 49, 50, 51, 52, 104, 108, 111, 99, 97, 116, 105, 111, 110, 191, 99, 108, 97, 116, 251, 64, 40, 153, 153, 153, 153, 153, 154, 99, 108, 110, 103, 251, 64, 65, 64, 0, 0, 0, 0, 0, 255, 255]

      it "encodes to cbor" do
        cbor = houses.to_cbor
        cbor.should eq(cbor_houses_bytes)
      end

      it "decodes form cbor" do
        decoded = Array(House).from_cbor(cbor_houses_bytes)

        decoded.size.should eq(1)
        house = decoded[0]
        house.address.should eq("Crystal Road 1234")

        loc = house.location
        loc.should_not be_nil
        loc.not_nil!.latitude.should eq(12.3)
        loc.not_nil!.longitude.should eq(34.5)
      end
    end

    describe "default values example" do
      it "respects default values" do
        A.from_cbor({"a" => 1}.to_cbor).inspect.should eq("A(@a=1, @b=1.0)")
      end
    end
  end
end
