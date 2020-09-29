class CBOR::Encoder
  def self.new(io : IO = IO::Memory.new)
    packer = new(io)
    yield packer
    packer
  end

  def initialize(@io : IO = IO::Memory.new)
  end

  def write(value : Nil | Nil.class, use_undefined : Bool = false)
    write(use_undefined ? SimpleValue::Undefined : SimpleValue::Null)
  end

  def write(value : Bool)
    write(value ? SimpleValue::True : SimpleValue::False)
  end

  def write(value : SimpleValue)
    write_size(0xe0, value.value)
  end

  def write(value : String)
    write_size(0x60, value.bytesize)
    write_slice(value.to_slice)
  end

  def write(value : Bytes)
    write_size(0x40, value.bytesize)
    write_slice(value)
  end

  def write(value : Symbol)
    write(value.to_s)
  end

  def write(value : Float32 | Float64)
    case value
    when Float32
      write_byte(0xfa)
    when Float64
      write_byte(0xfb)
    end
    write_value(value)
  end

  def write(value : Int8 | Int16 | Int32 | Int64)
    return write(value.to_u64) if value >= 0

    # When it's negative, transform it into a positive value and write the
    # resulting unsigned int with an offset
    positive_value = -(value + 1)
    write(positive_value.to_u64, 0x20)
  end

  # The Int128 can't be bigger than an UInt64 if positive or when inverted
  def write(value : Int128)
    if value > 0 && value <= UInt64::MAX
      return write(value.to_u64, 0x20)
    end

    # Flip the value
    positive_value = -(value + 1)

    # TODO: Use custom error
    raise ParseError.new("Negative Int128 too big, it must fit in a UInt64") if positive_value > UInt64::MAX

    write(positive_value.to_u, 0x20)
  end

  def write(value : UInt8 | UInt16 | UInt32 | UInt64, offset : UInt8 = 0x00)
    compressed = compress(value)

    # No need to write the value as the "size" contains the number
    write_size(offset, compressed)
  end

  def write(value : Hash)
    write_object_start(value.size)
    value.each do |key, val|
      write(key)
      write(val)
    end
  end

  def write(value : Array)
    write_array_start(value.size)
    value.each { |item| write(item) }
  end

  def write(value : Tuple)
    write_array_start(value.size)
    value.each { |item| write(item) }
  end

  def write(tag : Tag)
    compressed = compress(tag.value)
    write(compressed, 0xc0)
  end

  def write_array_start(size)
    write_size(0x80, size)
  end

  def write_object_start(size)
    write_size(0xa0, size)
  end

  def object(&block)
    write_map_start
    yield
    write_break
  end

  private def write_map_start
    write_byte(0xbf)
  end

  private def write_break
    write_byte(0xff)
  end

  # Find the smallest UInt capable of containing the value
  private def compress(value : UInt8 | UInt16 | UInt32 | UInt64)
    case value
    when .<= UInt8::MAX
      value.to_u8
    when .<= UInt16::MAX
      value.to_u16
    when .<= UInt32::MAX
      value.to_u32
    else
      value
    end
  end

  # Write the size flag for the se
  private def write_size(offset : UInt8, bytesize)
    case bytesize
    when 0x00..0x17
      write_byte(offset + bytesize)
    when 0x18..0xff
      write_byte(offset + 0x18)
      write_byte(bytesize.to_u8)
    when 0x0000..0xffff
      write_byte(offset + 0x19)
      write_value(bytesize.to_u16)
    when 0x0000_0000..0xffff_ffff
      write_byte(offset + 0x1a)
      write_value(bytesize.to_u32)
    when 0x0000_0000_0000_0000..0xffff_ffff_ffff_ffff
      write_byte(offset + 0x1b)
      write_value(bytesize.to_u64)
    else
      # TODO: Use a encoding error instead
      raise ParseError.new("invalid length")
    end
  end

  private def write_byte(byte : UInt8)
    @io.write_byte(byte)
  end

  private def write_slice(slice : Bytes)
    @io.write(slice)
  end

  private def write_value(value)
    @io.write_bytes(value, IO::ByteFormat::BigEndian)
  end

  def to_slice : Bytes
    io = @io
    raise "to slice not implemented for io type: #{typeof(io)}" unless io.responds_to?(:to_slice)
    io.to_slice
  end

  def to_s : String
    @io.to_s
  end
end
