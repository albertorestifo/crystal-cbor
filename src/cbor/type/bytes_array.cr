class CBOR::BytesArray < Array(UInt8)
  def to_a : Array(UInt8)
    self.as(Array(UInt8))
  end

  def to_bytes : Bytes
    Bytes.new(self.to_unsafe, self.size)
  end

  def to_diagnostic : String
    "(_ #{map(&to_byte_diagnostic).join(", ")})"
  end

  private def to_byte_diagnostic(i : UInt8) : String
    "h'#{i.hexstring}'"
  end
end
