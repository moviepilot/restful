#
#  Converts an APIModel to and from a given format.  
#
module Restful
  module Serializers
    class Base
      cattr_accessor :serializers
      
      def serialize(resource, options = {}) # implement me. 
        raise NotImplementedError.new
      end
      
      def deserialize(resource, options = {}) # implement me. 
        raise NotImplementedError.new        
      end
      
      #
      #  Grabs a serializer, given...
      #
      #    .serialize(:xml, Resource.new(:animal => "cow"))
      #
      def self.serializer(type)
        serializers[type].new
      end
      
      def self.serializer_name(key)
        self.serializers ||= {}
        self.serializers[key] = self
      end
      
      def formatted_value(value)
        return value unless value.respond_to?(:value)
        
        return nil if value.value.blank? && value.extended_type != :false_class
        case value.extended_type
        when :datetime
          value.value.xmlschema
        when :time
          value.value.xmlschema
        when :date
          value.value.to_s(:db)
        else
          value.value
        end        
      end
      
      protected
        def transform_link_name(name)
          name.to_s.gsub /_id$/, "-restful-url"
        end
      
        def revert_link_name(name)
          name.to_s.gsub /-restful-url$/, "_id"
        end      
    end
  end
end