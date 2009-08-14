require 'restful/serializers/base'

#
#  AR params hash.
#
module Restful
  module Serializers
    class HashSerializer < Base
      
      serializer_name :hash
      
      def serialize(resource, options = {})
        resource.is_a?(Restful::ApiModel::Collection) ?
          serialize_collection(resource) :
          serialize_tuples(resource.values, resource.full_url)
      end

      private      
        
        def serialize_collection(collection)
          values = collection.value.map { |r| serialize(r) }
        
          if entries = collection.total_entries
            values = { :total_entries => entries, collection.name => values }
          end
        
          values
        end
        
        def serialize_tuples(tuples, url)
          tuples.inject({ "restful_url" => url }) do |params, value|
            params[value.name.to_s.tr("-", "_").to_sym] = serialize_value(value)
            params
          end
        end
        
        def serialize_value(value)
          case value.type
            when :collection then serialize_collection(value)
            when :link       then Restful::Rails.tools.dereference(value.value)
            when :resource   then serialize(value)
            else                  formatted_value(value)
          end
        end

    end
  end
end