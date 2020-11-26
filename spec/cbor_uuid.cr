require "./spec_helper"

describe CBOR do
  describe "UUID" do
    it "UUID#to_cbor" do
      uuid = UUID.new "fc47eb8e-b13c-481e-863a-8f8c47a550f2"
      uuid.to_cbor.hexstring.should eq "50fc47eb8eb13c481e863a8f8c47a550f2"
    end

    it "UUID#from_cbor" do
      uuid = UUID.from_cbor "50fc47eb8eb13c481e863a8f8c47a550f2".hexbytes
      uuid.to_cbor.hexstring.should eq "50fc47eb8eb13c481e863a8f8c47a550f2"
    end
  end
end
