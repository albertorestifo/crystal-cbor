require "../spec_helper"

# Selection of tests from the RFC
tests = [
  # Float16 is not supportet for the encoding, so those tests will never work
  # {0.0, "f9 00 00"},
  # {-0.0, "f9 80 00"},
  # {1.0, "f9 3c 00"},
  # {1.5, "f9 3e 00"},
  # {65504.0, "f9 7b ff"},
  # {6.1035156e-5, "f9 04 00"},
  # {-4.0, "f9 c4 00"},
  # {5.9604645e-8, "f9 00 01"},

  {0, "00"},
  {1, "01"},
  {10, "0a"},
  {23, "17"},
  {24, "18 18"},
  {25, "18 19"},
  {100, "18 64"},
  {1000, "19 03 e8"},
  {1000000, "1a 00 0f 42 40"},
  {1000000000000, "1b 00 00 00 e8 d4 a5 10 00"},
  {18446744073709551615u64, "1b ff ff ff ff ff ff ff ff"},
  {-1, "20"},
  {-10, "29"},
  {-100, "38 63"},
  {-1000, "39 03 e7"},
  {1.1, "fb 3f f1 99 99 99 99 99 9a"},
  {100000.0_f32, "fa 47 c3 50 00"},
  {3.4028235e+38_f32, "fa 7f 7f ff ff"},
  {1.0e+300, "fb 7e 37 e4 3c 88 00 75 9c"},
  {-4.1, "fb c0 10 66 66 66 66 66 66"},
  {Float32::INFINITY, "fa 7f 80 00 00"},
  {Float32::NAN, "fa 7f c0 00 00"},
  {-Float32::INFINITY, "fa ff 80 00 00"},
  {Float64::INFINITY, "fb 7f f0 00 00 00 00 00 00"},
  {Float64::NAN, "fb 7f f8 00 00 00 00 00 00"},
  {-Float64::INFINITY, "fb ff f0 00 00 00 00 00 00"},
  {false, "f4"},
  {true, "f5"},
  {Nil, "f6"},
  {CBOR::SimpleValue::Undefined, "f7"},
  {CBOR::SimpleValue.new(16), "f0"},
  {CBOR::SimpleValue.new(24), "f8 18"},
  {CBOR::SimpleValue.new(255), "f8 ff"},
  {Bytes[0x01, 0x02, 0x03, 0x04], "44 01 02 03 04"},
  {"", "60"},
  {"a", "61 61"},
  {"IETF", "64 49 45 54 46"},
  {"\u00fc", "62 c3 bc"},
  {"\u6c34", "63 e6 b0 b4"},
  {[] of UInt8, "80"},
  {[1, 2, 3], "83 01 02 03"},
  {[1, [2, 3], [4, 5]], "83 01 82 02 03 82 04 05"},
  {[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25], "98 19 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 18 18 19"},
  {Hash(UInt8, UInt8).new, "a0"},
  { {1 => 2, 3 => 4}, "a2 01 02 03 04" },
  { {"a" => 1, "b" => [2, 3]}, "a2 61 61 01 61 62 82 02 03" },
  {["a", {"b" => "c"}], "82 61 61 a1 61 62 61 63"},
  { {"a" => "A", "b" => "B", "c" => "C", "d" => "D", "e" => "E"}, "a5 61 61 61 41 61 62 61 42 61 63 61 43 61 64 61 44 61 65 61 45" },
]

describe CBOR::Encoder do
  describe "with the RFC examples" do
    tests.each_with_index do |tt, index|
      describe "test ##{index}" do
        value, hex_string = tt

        bytes_arr = hex_string.split.map(&.to_u8(16))
        want_bytes = Bytes.new(bytes_arr.to_unsafe, bytes_arr.size)

        it "encodes #{value} to #{want_bytes.hexstring}" do
          res = IO::Memory.new

          encoder = CBOR::Encoder.new(res)
          encoder.write(value)

          res.to_slice.hexstring.should eq(want_bytes.hexstring)
        end
      end
    end
  end
end
