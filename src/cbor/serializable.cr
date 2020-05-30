module CBOR
  annotation Field
  end

  # The `CBOR::Serializable` module automatically generates methods for CBOR serialization when included.
  #
  # ### Example
  #
  # ```
  # require "cbor"
  #
  # class Location
  #   include CBOR::Serializable
  #
  #   @[CBOR::Field(key: "lat")]
  #   property latitude : Float64
  #
  #   @[CBOR::Field(key: "lng")]
  #   property longitude : Float64
  # end
  #
  # class House
  #   include CBOR::Serializable
  #
  #   property address : String
  #   property location : Location?
  # end
  #
  # house = House.from_cbor({"address" => "Crystal Road 1234", "location" => {"lat" => 12.3, "lng" => 34.5}}.to_cbor)
  # house.address  # => "Crystal Road 1234"
  # house.location # => #<Location:0x10cd93d80 @latitude=12.3, @longitude=34.5>
  # house.to_cbor  # => Bytes[...]
  #
  # houses = Array(House).from_cbor([{"address" => "Crystal Road 1234", "location" => {"lat" => 12.3, "lng" => 34.5}}].to_cbor)
  # houses.size    # => 1
  # houses.to_cbor # Bytes[...]
  # ```
  #
  # ### Usage
  #
  # Including `CBOR::Serializable` will create `#to_cbor` and `self.from_cbor` methods on the current class,
  # and a constructor which takes a `CBOR::Decoder`. By default, these methods serialize into a cbor
  # object containing the value of every instance variable, the keys being the instance variable name.
  # Most primitives and collections supported as instance variable values (string, integer, array, hash, etc.),
  # along with objects which define to_cbor and a constructor taking a `CBOR::Decoder`.
  # Union types are also supported, including unions with nil. If multiple types in a union parse correctly,
  # it is undefined which one will be chosen.
  #
  # To change how individual instance variables are parsed and serialized, the annotation `CBOR::Field`
  # can be placed on the instance variable. Annotating property, getter and setter macros is also allowed.
  # ```
  # require "cbor"
  #
  # class A
  #   include CBOR::Serializable
  #
  #   @[CBOR::Field(key: "my_key")]
  #   getter a : Int32?
  # end
  # ```
  #
  # `CBOR::Field` properties:
  # * **ignore**: if `true` skip this field in serialization and deserialization (by default false)
  # * **key**: the value of the key in the json object (by default the name of the instance variable)
  # * **converter**: specify an alternate type for parsing and generation. The converter must define `from_cbor(CBOR::Decoder)` and `to_cbor(value, CBOR::Builder)` as class methods. Examples of converters are `Time::Format` and `Time::EpochConverter` for `Time`.
  # * **presence**: if `true`, a `@{{key}}_present` instance variable will be generated when the key was present (even if it has a `null` value), `false` by default
  # * **emit_null**: if `true`, emits a `null` value for nilable property (by default nulls are not emitted)
  # * **nil_as_undefined**: if `true`, when the value is `nil`, it is emitted as `undefined` (by default `nil` are encoded as `null`)
  #
  # Deserialization also respects default values of variables:
  # ```
  # require "cbor"
  #
  # struct A
  #   include CBOR::Serializable
  #   @a : Int32
  #   @b : Float64 = 1.0
  # end
  #
  # A.from_cbor({"a" => 1}.to_cbor) # => A(@a=1, @b=1.0)
  # ```
  #
  # ### Extensions: `CBOR::Serializable::Unmapped`.
  #
  # If the `CBOR::Serializable::Unmapped` module is included, unknown properties in the CBOR
  # document will be stored in a `Hash(String, CBOR::Type)`. On serialization, any keys inside cbor_unmapped
  # will be serialized and appended to the current json object.
  # ```
  # require "cbor"
  #
  # struct A
  #   include JSON::Serializable
  #   include JSON::Serializable::Unmapped
  #   @a : Int32
  # end
  #
  # a = A.from_json(%({"a":1,"b":2})) # => A(@json_unmapped={"b" => 2_i64}, @a=1)
  # a.to_json                         # => {"a":1,"b":2}
  # ```
  #
  #
  # ### Class annotation `CBOR::Serializable::Options`
  #
  # supported properties:
  # * **emit_nulls**: if `true`, emits a `null` value for all nilable properties (by default nulls are not emitted)
  # * **nil_as_undefined**: if `true`, emits a `nil` value as undefined (by default nil emits `null`)
  #
  # ```
  # require "json"
  #
  # @[CBOR::Serializable::Options(emit_nulls: true)]
  # class A
  #   include JSON::Serializable
  #   @a : Int32?
  # end
  # ```
  #
  # ### Discriminator field
  #
  # A very common JSON serialization strategy for handling different objects
  # under a same hierarchy is to use a discriminator field. For example in
  # [GeoJSON](https://tools.ietf.org/html/rfc7946) each object has a "type"
  # field, and the rest of the fields, and their meaning, depend on its value.
  #
  # You can use `JSON::Serializable.use_json_discriminator` for this use case.
  module Serializable
    annotation Options
    end

    macro included
      # Define a `new` directly in the included type,
      # so it overloads well with other possible initializes

      def self.new(decoder : ::CBOR::Decoder)
        new_from_cbor_decoder(decoder)
      end

      private def self.new_from_cbor_decoder(decoder : ::CBOR::Decoder)
        instance = allocate
        instance.initialize(__decoder_for_cbor_serializable: decoder)
        GC.add_finalizer(instance) if instance.responds_to?(:finalize)
        instance
      end

      # When the type is inherited, carry over the `new`
      # so it can compete with other possible intializes

      macro inherited
        def self.new(decoder : ::CBOR::Decoder)
          new_from_cbor_decoder(decoder)
        end
      end
    end

    def initialize(*, __decoder_for_cbor_serializable decoder : ::CBOR::Decoder)
      {% begin %}
        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::CBOR::Field) %}
          {% unless ann && ann[:ignore] %}
            {%
              properties[ivar.id] = {
                type:        ivar.type,
                key:         ((ann && ann[:key]) || ivar).id.stringify,
                has_default: ivar.has_default_value?,
                default:     ivar.default_value,
                nilable:     ivar.type.nilable?,
                converter:   ann && ann[:converter],
                presence:    ann && ann[:presence],
              }
            %}
          {% end %}
        {% end %}

        {% for name, value in properties %}
          %var{name} = nil
          %found{name} = false
        {% end %}

        begin
          decoder.read_begin_hash
        rescue exc : ::CBOR::ParseError
          raise ::CBOR::SerializationError.new(exc.message, self.class.to_s, nil)
        end

        decoder.consume_hash do
          key = decoder.read_string
          case key
          {% for name, value in properties %}
            when {{value[:key]}}
              %found{name} = true
              begin
                %var{name} =
                  {% if value[:nilable] || value[:has_default] %} decoder.read_nil_or { {% end %}

                  {% if value[:converter] %}
                    {{value[:converter]}}.from_cbor(decoder)
                  {% else %}
                    ::Union({{value[:type]}}).new(decoder)
                  {% end %}

                {% if value[:nilable] || value[:has_default] %} } {% end %}
              rescue exc : ::CBOR::ParseError
                raise ::CBOR::SerializationError.new(exc.message, self.class.to_s, {{value[:key]}})
              end
          {% end %}
          else
            on_unknown_cbor_attribute(decoder, key)
          end
        end

        {% for name, value in properties %}
          {% unless value[:nilable] || value[:has_default] %}
            if %var{name}.nil? && !%found{name} && !::Union({{value[:type]}}).nilable?
              raise ::CBOR::SerializationError.new("Missing CBOR attribute: {{value[:key].id}}", self.class.to_s, nil)
            end
          {% end %}

          {% if value[:nilable] %}
            {% if value[:has_default] != nil %}
              @{{name}} = %found{name} ? %var{name} : {{value[:default]}}
            {% else %}
              @{{name}} = %var{name}
            {% end %}
          {% elsif value[:has_default] %}
            @{{name}} = %var{name}.nil? ? {{value[:default]}} : %var{name}
          {% else %}
            @{{name}} = (%var{name}).as({{value[:type]}})
          {% end %}

          {% if value[:presence] %}
            @{{name}}_present = %found{name}
          {% end %}
        {% end %}
      {% end %}
      after_initialize
    end

    protected def after_initialize
    end

    protected def on_unknown_cbor_attribute(decoder, key)
      raise ::CBOR::SerializationError.new("Unknown CBOR attribute: #{key}", self.class.to_s, nil)
    end

    protected def on_to_cbor(cbor : ::CBOR::Encoder)
    end

    def to_cbor(cbor : ::CBOR::Encoder)
      {% begin %}
        {% options = @type.annotation(::CBOR::Serializable::Options) %}
        {% emit_nulls = options && options[:emit_nulls] %}
        {% nil_as_undefined = options && options[:nil_as_undefined] %}

        {% properties = {} of Nil => Nil %}
        {% for ivar in @type.instance_vars %}
          {% ann = ivar.annotation(::CBOR::Field) %}
          {% unless ann && ann[:ignore] %}
            {%
              properties[ivar.id] = {
                type:             ivar.type,
                key:              ((ann && ann[:key]) || ivar).id.stringify,
                converter:        ann && ann[:converter],
                emit_null:        (ann && (ann[:emit_null] != nil) ? ann[:emit_null] : emit_nulls),
                nil_as_undefined: (ann && (ann[:nil_as_undefined] != nil) ? ann[:nil_as_undefined] : nil_as_undefined),
              }
            %}
          {% end %}
        {% end %}

        cbor.object do
          {% for name, value in properties %}
            _{{name}} = @{{name}}

            {% unless value[:emit_null] %}
              unless _{{name}}.nil?
            {% end %}

              # Write the key of the map
              cbor.write({{value[:key]}})

              {% if value[:converter] %}
                if _{{name}}
                  {{ value[:converter] }}.to_cbor(_{{name}}, cbor)
                else
                  cbor.write(nil, use_undefined: value[:nil_as_undefined])
                end
              {% else %}
                _{{name}}.to_cbor(cbor)
              {% end %}

            {% unless value[:emit_null] %}
              end
            {% end %}
          {% end %}
          on_to_cbor(cbor)
        end
      {% end %}
    end

    module Unmapped
      @[CBOR::Field(ignore: true)]
      property cbor_unmapped = Hash(String, ::CBOR::Type).new

      protected def on_unknown_cbor_attribute(decoder, key)
        cbor_unmapped[key] = begin
          decoder.read_value
        rescue exc : ::CBOR::ParseError
          raise ::CBOR::SerializationError.new(exc.message, self.class.to_s, key)
        end
      end

      protected def on_to_cbor(cbor : ::CBOR::Encoder)
        cbor_unmapped.each do |key, value|
          cbor.write(key)
          value.to_cbor(cbor)
        end
      end
    end

    # Tells this class to decode CBOR by using a field as a discriminator.
    #
    # - *field* must be the field name to use as a discriminator
    # - *mapping* must be a hash or named tuple where each key-value pair
    #   maps a discriminator value to a class to deserialize
    #
    # For example:
    #
    # ```
    # require "cbor"
    #
    # abstract class Shape
    #   include CBOR::Serializable
    #
    #   use_cbor_discriminator "type", {point: Point, circle: Circle}
    #
    #   property type : String
    # end
    #
    # class Point < Shape
    #   property x : Int32
    #   property y : Int32
    # end
    #
    # class Circle < Shape
    #   property x : Int32
    #   property y : Int32
    #   property radius : Int32
    # end
    #
    # TODO: Update examples
    # Shape.from_cbor(%({"type": "point", "x": 1, "y": 2}))               # => #<Point:0x10373ae20 @type="point", @x=1, @y=2>
    # Shape.from_cbor(%({"type": "circle", "x": 1, "y": 2, "radius": 3})) # => #<Circle:0x106a4cea0 @type="circle", @x=1, @y=2, @radius=3>
    # ```
    # macro use_cbor_discriminator(field, mapping)
    #   {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
    #     {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
    #   {% end %}

    #   def self.new(decoder : ::CBOR::Decoder)
    #     discriminator_value = nil

    #     # Try to find the discriminator while also getting the raw
    #     # string value of the parsed JSON, so then we can pass it
    #     # to the final type.
    #     json = String.build do |io|
    #       JSON.build(io) do |builder|
    #         builder.start_object
    #         pull.read_object do |key|
    #           if key == {{field.id.stringify}}
    #             discriminator_value = pull.read_string
    #             builder.field(key, discriminator_value)
    #           else
    #             builder.field(key) { pull.read_raw(builder) }
    #           end
    #         end
    #         builder.end_object
    #       end
    #     end

    #     unless discriminator_value
    #       raise ::JSON::MappingError.new("Missing JSON discriminator field '{{field.id}}'", to_s, nil, *location, nil)
    #     end

    #     case discriminator_value
    #     {% for key, value in mapping %}
    #       when {{key.id.stringify}}
    #         {{value.id}}.from_json(json)
    #     {% end %}
    #     else
    #       raise ::JSON::MappingError.new("Unknown '{{field.id}}' discriminator value: #{discriminator_value.inspect}", to_s, nil, *location, nil)
    #     end
    #   end
    # end
  end
end
