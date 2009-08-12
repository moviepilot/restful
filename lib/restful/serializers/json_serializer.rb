require 'restful/serializers/base'
require 'yajl'

#
#  AR params hash.
#
module Restful
  module Serializers
    class JsonSerializer < Base
      
      serializer_name :json
      
      def serialize(resource, options = {})
        params = {}
        
        resource.values.each do |value|
          if value.type == :collection # serialize the stuffs
            resources = value.value
            name = resources.first.name.pluralize
            
            array = []
            resources.each do |resource|
              array << serialize(resource)
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
        
        Yajl::Encoder.encode(params)
      end
    end
  end
end