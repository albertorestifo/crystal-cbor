class CBOR::BytesArray < Array(Bytes)
  def to_bytes : Bytes
    size = reduce(0) { |acc, chunk| acc + chunk.size }
    bytes = Bytes.new(size)

    # Copy each chunk into the new bytes slice
    ptr = bytes.to_unsafe
    each do |chunk|
      chunk.copy_to(ptr, chunk.size)
      ptr += chunk.size
    end

    bytes
  end
end
