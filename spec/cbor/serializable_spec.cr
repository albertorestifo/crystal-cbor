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

struct Headers
  include CBOR::Serializable

  @[CBOR::Field(key: 1)]
  getter one : Int32
  @[CBOR::Field(key: 4)]
  getter four : Bytes
  getter address : Bytes
end

describe CBOR::Serializable do
  describe "rfc examples" do
    describe %(example {"a": 1, "b": [2, 3]}) do
      it "decodes from cbor" do
        result = ExampleA.from_cbor(Bytes[0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff])

        result.a.should eq(1)
        result.b.should eq([2, 3])
      end
    end

    describe %(example {"Fun": true, "Amt": -2}) do
      it "decodes from cbor" do
        result = ExampleB.from_cbor(Bytes[0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff])

        result.is_fun.should be_true
        result.amt.should eq(-2)
      end
    end

    describe %(example ["a", {"b": "c"}]) do
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
      data = {
        "address"  => "Crystal Road 1234",
        "location" => {"lat" => 12.3, "lng" => 34.5},
      }
      bytes = data.to_cbor

      it "has the correct starting data" do
        CBOR::Diagnostic.to_s(bytes).should eq(%({"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}))
      end

      it "decodes from CBOR" do
        house = House.from_cbor(bytes)

        house.address.should eq("Crystal Road 1234")
        loc = house.location
        loc.should_not be_nil
        loc.not_nil!.latitude.should eq(12.3)
        loc.not_nil!.longitude.should eq(34.5)
      end

      it "encodes to CBOR" do
        cbor = House.from_cbor(bytes).to_cbor
        CBOR::Diagnostic.to_s(cbor).should eq(%({"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}))
      end
    end

    describe "houses array" do
      data = [{
        "address"  => "Crystal Road 1234",
        "location" => {"lat" => 12.3, "lng" => 34.5},
      }]
      bytes = data.to_cbor

      it "has the correct starting data" do
        CBOR::Diagnostic.to_s(bytes).should eq(%([{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]))
      end

      it "decodes from CBOR" do
        houses = Array(House).from_cbor(bytes)

        houses.size.should eq(1)
        house = houses[0]
        house.address.should eq("Crystal Road 1234")

        loc = house.location
        loc.should_not be_nil
        loc.not_nil!.latitude.should eq(12.3)
        loc.not_nil!.longitude.should eq(34.5)
      end

      it "encodes to CBOR" do
        cbor = Array(House).from_cbor(bytes).to_cbor

        CBOR::Diagnostic.to_s(cbor).should eq(%([{"address": "Crystal Road 1234", "location": {"lat": 12.3, "lng": 34.5}}]))
      end
    end

    describe "default values example" do
      it "respects default values" do
        A.from_cbor({"a" => 1}.to_cbor).inspect.should eq("A(@a=1, @b=1.0)")
      end
    end

    describe "Unmapped extension" do
      it "decodes with the values in cbor_unmapped" do
        res = ExampleUnmapped.from_cbor({"a" => 1, "b" => 2}.to_cbor)

        res.a.should eq(1)
        res.cbor_unmapped.should eq({"b" => 2})

        CBOR::Diagnostic.to_s(res.to_cbor).should eq(%({"a": 1, "b": 2}))
      end
    end
  end

  describe "numeric keys example" do
    it "parses objects with numeric keys" do
      headers = Bytes[163, 1, 39, 4, 88, 32, 93, 155, 209, 93, 43, 36, 29, 66, 174, 118, 124, 101, 62, 74, 170, 46, 169, 227, 178, 210, 218, 102, 240, 224, 157, 19, 185, 105, 29, 18, 240, 51, 103, 97, 100, 100, 114, 101, 115, 115, 88, 57, 1, 228, 116, 11, 38, 144, 121, 29, 229, 235, 173, 0, 234, 85, 93, 140, 108, 49, 49, 142, 169, 128, 153, 158, 183, 177, 58, 36, 185, 85, 194, 158, 26, 190, 164, 89, 60, 82, 102, 11, 144, 182, 250, 32, 179, 229, 164, 43, 16, 86, 102, 82, 42, 63, 20, 175, 41]

      result = Headers.from_cbor(headers)
      result.one.should eq(-8)
      result.four.hexstring.should start_with("5d9bd15d2b241d42")
      result.address.hexstring.should start_with("01e4740b2690791d")
    end
  end
end
