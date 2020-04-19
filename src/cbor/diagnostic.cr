module CBOR::Diagnostic
  def to_s(value : CBOR::ByteArray) : String
    value.to_diagnostic
  end

  {% for type in [UInt8, Int8, UInt16, Int16, UInt32, Int32, UInt64, Int64, Int128] %}
    def to_s(value : {{type}}) : String
      {{type}}.to_s
    end
  {% end %}

  def to_s(value : String)
    %("#{value}")
  end
end
