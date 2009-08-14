require 'restful/serializers/base'

#
#  AR params hash.
#
module Restful
  module Serializers
    class HashSerializer < Base
      
      serializer_name :hash
      
      def serialize(resource, options = {})
        if resource.is_a?(Restful::ApiModel::Collection)
          serialize_array(resource.value)
        else
          serialize_collection(resource)
        end
      end
      
      private      
      
        def hashify_key(original_key)
          original_key.to_s.tr("-", "_").to_sym
        end
        
        def serialize_collection(resource)
          resource.values.inject({ "restful_url" => resource.full_url }) do |params, value|
            params[hashify_key(value.name)] = serialize_value(value)
            params
          end
        end
        
        def serialize_array(resources)
          resources.map { |r| serialize(r) }
        end
        
        def serialize_value(value)
          case value.type
            when :collection then serialize_array(value.value)
            when :link       then Restful::Rails.tools.dereference(value.value)
            when :resource   then serialize(value)
            else                  formatted_value(value)
          end
        end

    end
  end
end