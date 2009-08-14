require 'restful/serializers/base'

#
#  AR params hash.
#
module Restful
  module Serializers
    class HashSerializer < Base
      
      serializer_name :hash

      
      def serialize(resource, options = {})
        params = { "restful_url" => resource.full_url }
        resource.values.each do |value|
          params[hashify_key(value.name)] = serialize_value(value)
        end
        params
      end
      
      private
      
        def hashify_key(original_key)
          original_key.to_s.tr("-", "_").to_sym
        end
        
        def serialize_value(value)
          case value.type
            when :collection then serialize_collection(value.value)
            when :link       then Restful::Rails.tools.dereference(value.value)
            when :resource   then serialize(value)
            else                  formatted_value(value)
          end
        end
        
        def serialize_collection(resources)
          returning [] do |array|
            resources.each do |r|
              array << serialize(r)
            end
          end
        end
    end
  end
end