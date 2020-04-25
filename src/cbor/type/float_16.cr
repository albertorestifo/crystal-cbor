# Returns a Float32 by reading the 16 bit as a IEEE 754 half-precision floating
# point (Float16).
def Float32.new(i : UInt16)
  # Check for signed zero
  if i & 0x7FFF_u16 == 0
    return (i.unsafe_as(UInt32) << 16).unsafe_as(Float32)
  end

  half_sign = (i & 0x8000_u16).unsafe_as(UInt32)
  half_exp = (i & 0x7C00_u16).unsafe_as(UInt32)
  half_man = (i & 0x03FF_u16).unsafe_as(UInt32)

  # Check for an infinity or NaN when all exponent bits set
  if half_exp == 0x7C00_u32
    # Check for signed infinity if mantissa is zero
    if half_man == 0
      return ((half_sign << 16) | 0x7F80_0000_u32).unsafe_as(Float32)
    else
      # NaN, keep current mantissa but also set most significiant mantissa bit
      return ((half_sign << 16) | 0x7FC0_0000_u32 | (half_man << 13)).unsafe_as(Float32)
    end
  end

  # Calculate single-precision components with adjusted exponent
  sign = half_sign << 16
  # Unbias exponent
  unbiased_exp = ((half_exp.unsafe_as(Int32)) >> 10) - 15

  # Check for subnormals, which will be normalized by adjusting exponent
  if half_exp == 0
    # Calculate how much to adjust the exponent by
    e = half_man.unsafe_as(UInt16).leading_zeros_count - 6

    # Rebias and adjust exponent
    exp = (127 - 15 - e) << 23
    man = (half_man << (14 + e)) & 0x7F_FF_FF_u32
    return (sign | exp | man).unsafe_as(Float32)
  end

  # Rebias exponent for a normalized normal
  exp = (unbiased_exp + 127).unsafe_as(UInt32) << 23
  man = (half_man & 0x03FF_u32) << 13
  (sign | exp | man).unsafe_as(Float32)
end
