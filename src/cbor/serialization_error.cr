class CBOR::SerializationError < Exception
  getter klass : String

  def initialize(message : String?, @klass : String, @attribute : String?)
    message = String.build do |io|
      io << message
      io << "\n  parsing "
      io << klass
      if attribute = @attribute
        io << '#' << attribute
      end
    end

    super(message)
  end
end
