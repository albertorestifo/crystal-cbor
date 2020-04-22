class CBOR::StringArray < Array(String)
  def to_s : String
    join
  end

  def to_diagnostic : String
    "(_ #{map { |s| quote(s) }.join(", ")})"
  end

  private def quote(chunk : String) : String
    %("#{chunk}")
  end
end
