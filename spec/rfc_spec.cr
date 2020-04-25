require "./spec_helper"

# All those tests have been exported from the RFC7049 appendix A.

tests = [
  # Disabled as half-precision floats are not supported:
  { %(0.0), "f9 00 00" },
  { %(-0.0), "f9 80 00" },
  { %(1.0), "f9 3c 00" },
  { %(1.5), "f9 3e 00" },
  { %(65504.0), "f9 7b ff" },
  # { %(0.00006103515625), "f9 04 00" }, TODO: Something about the presentation
  { %(-4.0), "f9 c4 00" },
  # { %(5.960464477539063e-8), "f9 00 01" },
  # { %(Infinity), "f9 7c 00" },
  # { %(NaN), "f9 7e 00" },
  # { %(-Infinity), "f9 fc 00" },

  { %(0), "00" },
  { %(1), "01" },
  { %(10), "0a" },
  { %(23), "17" },
  { %(24), "18 18" },
  { %(25), "18 19" },
  { %(100), "18 64" },
  { %(1000), "19 03 e8" },
  { %(1000000), "1a 00 0f 42 40" },
  { %(1000000000000), "1b 00 00 00 e8 d4 a5 10 00" },
  { %(18446744073709551615), "1b ff ff ff ff ff ff ff ff" },
  { %(18446744073709551616), "c2 49 01 00 00 00 00 00 00 00 00" },
  { %(-18446744073709551616), "3b ff ff ff ff ff ff ff ff" },
  { %(-18446744073709551617), "c3 49 01 00 00 00 00 00 00 00 00" },
  { %(-1), "20" },
  { %(-10), "29" },
  { %(-100), "38 63" },
  { %(-1000), "39 03 e7" },
  { %(1.1), "fb 3f f1 99 99 99 99 99 9a" },
  { %(100000.0), "fa 47 c3 50 00" },
  # { %(3.4028234663852886e+38), "fa 7f 7f ff ff" }, TODO: Not precise enough?
  { %(1.0e+300), "fb 7e 37 e4 3c 88 00 75 9c" },
  { %(-4.1), "fb c0 10 66 66 66 66 66 66" },
  { %(Infinity), "fa 7f 80 00 00" },
  { %(NaN), "fa 7f c0 00 00" },
  { %(-Infinity), "fa ff 80 00 00" },
  { %(Infinity), "fb 7f f0 00 00 00 00 00 00" },
  { %(NaN), "fb 7f f8 00 00 00 00 00 00" },
  { %(-Infinity), "fb ff f0 00 00 00 00 00 00" },
  { %(false), "f4" },
  { %(true), "f5" },
  { %(null), "f6" },
  { %(undefined), "f7" },
  { %(simple(16)), "f0" },
  { %(simple(24)), "f8 18" },
  { %(simple(255)), "f8 ff" },
  { %(0("2013-03-21T20:04:00Z")), "c0 74 32 30 31 33 2d 30 33 2d 32 31 54 32 30 3a 30 34 3a 30 30 5a" },
  { %(1(1363896240)), "c1 1a 51 4b 67 b0" },
  { %(1(1363896240.5)), "c1 fb 41 d4 52 d9 ec 20 00 00" },
  { %(23(h'01020304')), "d7 44 01 02 03 04" },
  { %(24(h'6449455446')), "d8 18 45 64 49 45 54 46" },
  { %(32("http://www.example.com")), "d8 20 76 68 74 74 70 3a 2f 2f 77 77 77 2e 65 78 61 6d 70 6c 65 2e 63 6f 6d" },
  { %(h''), "40" },
  { %(h'01020304'), "44 01 02 03 04" },
  { %(""), "60" },
  { %("a"), "61 61" },
  { %("IETF"), "64 49 45 54 46" },
  { %(""\\"), "62 22 5c" },
  { %("\u00fc"), "62 c3 bc" },
  { %("\u6c34"), "63 e6 b0 b4" },
  # { %("\ud800\udd51"), "64 f0 90 85 91" }, TODO: Maybe there is a problem with unicode escaping? Or maybe it's just the diagnostics
  { %([]), "80" },
  { %([1, 2, 3]), "83 01 02 03" },
  { %([1, [2, 3], [4, 5]]), "83 01 82 02 03 82 04 05" },
  { %([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]), "98 19 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 18 18 19" },
  { %({}), "a0" },
  { %({1: 2, 3: 4}), "a2 01 02 03 04" },
  { %({"a": 1, "b": [2, 3]}), "a2 61 61 01 61 62 82 02 03" },
  { %(["a", {"b": "c"}]), "82 61 61 a1 61 62 61 63" },
  { %({"a": "A", "b": "B", "c": "C", "d": "D", "e": "E"}), "a5 61 61 61 41 61 62 61 42 61 63 61 43 61 64 61 44 61 65 61 45" },
  { %((_ h'0102', h'030405')), "5f 42 01 02 43 03 04 05 ff" },
  { %((_ "strea", "ming")), "7f 65 73 74 72 65 61 64 6d 69 6e 67 ff" },
  { %([_ ]), "9f ff" },
  { %([_ 1, [2, 3], [_ 4, 5]]), "9f 01 82 02 03 9f 04 05 ff ff" },
  { %([_ 1, [2, 3], [4, 5]]), "9f 01 82 02 03 82 04 05 ff" },
  { %([1, [2, 3], [_ 4, 5]]), "83 01 82 02 03 9f 04 05 ff" },
  { %([1, [_ 2, 3], [4, 5]]), "83 01 9f 02 03 ff 82 04 05" },
  { %([_ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]), "9f 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10 11 12 13 14 15 16 17 18 18 18 19 ff" },
  { %({_ "a": 1, "b": [_ 2, 3]}), "bf 61 61 01 61 62 9f 02 03 ff ff" },
  { %(["a", {_ "b": "c"}]), "82 61 61 bf 61 62 61 63 ff" },
  { %({_ "Fun": true, "Amt": -2}), "bf 63 46 75 6e f5 63 41 6d 74 21 ff" },
]

describe "Examples from RFC7049 Appendix A" do
  tests.each_with_index do |tt, index|
    describe "test ##{index}" do
      diagnostic, hex_string = tt

      bytes_arr = hex_string.split.map(&.to_u8(16))
      bytes = Bytes.new(bytes_arr.to_unsafe, bytes_arr.size)

      it "reads #{bytes.hexstring} as #{diagnostic}" do
        result = CBOR::Diagnostic.new(bytes).to_s

        result.should eq(diagnostic)
      end
    end
  end
end
