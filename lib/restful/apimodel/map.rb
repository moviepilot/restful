#
#  Resource model. Something like a DOM model for the api. 
#
module Restful
  module ApiModel
    class Map
      attr_accessor :values, :name, :type

      def initialize(name)
        self.name = name
        self.type = :hash
        self.values = []
      end

      def links
        self.values.select { |attribute| attribute.type == :link }
      end

      def simple_attributes
        self.values.select { |attribute| attribute.type == :simple_attribute }        
      end

      def collections
        self.values.select { |attribute| attribute.type == :collection }
      end

      # invoke serialization
      def serialize(type)
        serializer = Restful::Serializers::Base.serializer(type)
        serializer.serialize(self)
      end

      # invoke deserialization
      def deserialize_from(type)
        serializer = Restful::Serializers::Base.serializer(type)
        serializer.deserialize(self)
      end
    end
  end
end

