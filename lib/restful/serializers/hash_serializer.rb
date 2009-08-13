require 'restful/serializers/base'

#
#  AR params hash.
#
module Restful
  module Serializers
    class HashSerializer < Base
      
      serializer_name :hash

      
      def serialize(resource, options = {})
        params = {}
        
        resource.values.each do |value|
          if value.type == :collection # serialize the stuffs
            resources = value.value
            next if resources.empty?
            name = resources.first.name.pluralize
            
            array = []
            resources.each do |r|
              array << serialize(r)
            end
            
            params["#{value.name}".to_sym] = array
          elsif value.type == :link
            params[value.name] = Restful::Rails.tools.dereference(value.value)
          elsif value.type == :resource
            params["#{value.name}".to_sym] = serialize(value)
          else # plain ole
            string_value = case value.extended_type
            when :datetime
              value.value.xmlschema
            else
              value.value
            end
            
            params[value.name] = string_value
          end
        end
        
        params["restful_url"] = resource.full_url
        params
      end
    end
  end
end