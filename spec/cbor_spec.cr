require "./spec_helper"

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

  def initialize(@address)
  end
end

class Person
  include CBOR::Serializable
  include CBOR::Serializable::Unmapped

  property name : String?

  def initialize(@name = nil)
  end
end

describe CBOR do
  describe "basics: to_cbor" do
    it "empty array" do
      empty_array_cbor = [] of Nil
      empty_array_cbor.to_cbor.hexstring.should eq "80"
    end

    it "array - strings" do
      ["a", "b", "c"].to_cbor.hexstring.should eq "83616161626163"
    end

    it "empty hash" do
      empty = {} of Nil => Nil
      cbor_stuff = empty.to_cbor
      cbor_stuff.hexstring.should eq "a0"
    end

    it "hash" do
      {"a" => 10, "b" => true, "c" => nil}.to_cbor.hexstring.should eq "a361610a6162f56163f6"
    end

    it "union String | Int32" do
      value = (String | Int32).from_cbor(30.to_cbor).to_cbor
      value.hexstring.should eq "181e"
    end
    it "union (String | Int32)" do
      value = (String | Int32).from_cbor("blah".to_cbor).to_cbor
      value.hexstring.should eq "64626c6168"
    end
    it "union (Bool | Int32)" do
      value = (Bool | Int32).from_cbor(30.to_cbor).to_cbor
      value.hexstring.should eq "181e"
    end
    it "union (Bool | Int32)" do
      value = (Bool | Int32).from_cbor(false.to_cbor).to_cbor
      value.hexstring.should eq "f4"
    end
    it "union (String | Bool | Int32)" do
      value = (String | Bool | Int32).from_cbor("hello".to_cbor).to_cbor
      value.hexstring.should eq "6568656c6c6f"
    end
    it "union (String | Nil | Int32)" do
      value = (String | Nil | Int32).from_cbor(nil.to_cbor).to_cbor
      value.hexstring.should eq "f6"
    end
  end

  describe "CBOR library annotations and features" do
    it "House#to_cbor with CBOR::Field annotations" do
      house = House.new "my address"
      house.location = Location.new 1.1, 1.2
      house.to_cbor.hexstring.should eq "a267616464726573736a6d792061646472657373686c6f636174696f6ea2636c6174fb3ff199999999999a636c6e67fb3ff3333333333333"
    end

    it "House#from_cbor with CBOR::Field annotations" do
      other_house = House.new "my address"
      other_house.location = Location.new 1.1, 1.2

      house = House.from_cbor other_house.to_cbor
      house.to_cbor.hexstring.should eq "a267616464726573736a6d792061646472657373686c6f636174696f6ea2636c6174fb3ff199999999999a636c6e67fb3ff3333333333333"
    end

    it "Person#from_cbor with unmapped values" do
      h = Hash(String | Int32, String | Int32).new
      h["name"] = "Alice"
      h["age"] = 30
      h["size"] = 160
      alice = Person.from_cbor h.to_cbor
      alice.to_cbor.hexstring.should eq "a3646e616d6565416c69636563616765181e6473697a6518a0"
    end

    it "Person#to_cbor with unmapped values" do
      alice = Person.new "Alice"
      alice.cbor_unmapped["age"] = 30
      alice.cbor_unmapped["size"] = 160
      alice.to_cbor.hexstring.should eq "a3646e616d6565416c69636563616765181e6473697a6518a0"
    end
  end
end
