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
            
            params["#{value.name.to_sym}_attributes".to_sym] = array
          elsif value.type == :link
            params[value.name] = Restful::Rails.tools.dereference(value.value)
          elsif value.type == :resource
            params["#{value.name.to_sym}_attributes".to_sym] = serialize(value)
          else # plain ole
            params[value.name] = value.value
          end
        end
        
        params
      end
    end
  end
end
