#
#  Converts an APIModel to and from a given format.  
#
module Restful
  module Serializers
    class Base
      cattr_accessor :serializers
      
      def serialize(resource, options = {})
        raise NotImplementedError.new
      end
      
      def deserialize(resource, options = {})
        raise NotImplementedError.new        
      end
      
      #
      #  Grabs a serializer, given...
      #
      #    #serialize :xml, Resource.new(:animal => "cow")
      #
      def self.serializer(type)
        serializers[type].new
      end
      
      def self.serializer_name(key)
        self.serializers ||= {}
        self.serializers[key] = self
      end
      
      def serialize_attribute(attribute)
        return formatted_ruby_type(attribute) unless attribute.respond_to?(:value)
        return nil if attribute.value.blank? && attribute.extended_type != :false_class
        
        formatted_ruby_type(attribute.value)
      end
      
      def formatted_ruby_type(obj)
        case obj
          when DateTime then obj.xmlschema
          when Time     then obj.xmlschema
          when Date     then obj.to_s(:db)
          else
            obj
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