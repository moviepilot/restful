require 'restful/serializers/base'
require 'builder'

#
#  AR params hash.
#
module Restful
  module Serializers
    class ParamsSerializer < Base
      
      serializer_name :params
      
      def serialize(resource, options = {})
        params = {}
        resource.values.each do |value|
          if value.type == :collection # serialize the stuffs
            resources = value.value
            next if resources.empty?
            name = resources.first.name.pluralize
            
            array = []
            resources.each do |resource|
              array << serialize(resource)
            end              
            
            params["#{paramify_keys(value.name)}_attributes".to_sym] = array
          elsif value.type == :link
            params[paramify_keys(value.name).to_sym] = Restful::Rails.tools.dereference(value.value)
          elsif value.type == :resource
            params["#{paramify_keys(value.name)}_attributes".to_sym] = serialize(value)
          else # plain ole
            params[paramify_keys(value.name).to_sym] = value.value # no need to format dates etc - just pass objects through. 
          end
        end
        
        params
      end
      
      private
      
      def paramify_keys(original_key)
        original_key.to_s.tr("-", "_")
      end
    end    
  end
end
