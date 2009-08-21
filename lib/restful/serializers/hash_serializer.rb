require 'restful/serializers/base'

#
#  Vanilla Hash.
#
module Restful
  module Serializers
    class HashSerializer < Base
      
      serializer_name :hash
      
      def serialize(obj, options = {})
        case obj.type
          when :link              then obj.value
          when :simple_attribute  then serialize(obj.value)
          when :collection        then serialize_collection(obj)
          when :map               then serialize_array_of_apimodels(obj.values)
          when :resource          then serialize_array_of_apimodels(obj.values, { "restful_url" => obj.full_url })
          else
            formatted_ruby_type(obj)
          end
      end
      
      private      
        
        def serialize_collection(collection)
          if entries = collection.total_entries
            { :total_entries => entries, collection.name => serialize_unpaginated_collection(collection) }
          else
            serialize_unpaginated_collection(collection)
          end
        end
        
        def serialize_unpaginated_collection(collection)
          collection.value.map { |r| serialize(r) }
        end
        
        def serialize_array_of_apimodels(apimodels, defaults = {})
          apimodels.inject(defaults) do |memo, apimodel|
            memo[apimodel.name.to_s.underscore.to_sym] = serialize(apimodel)
            memo
          end          
        end
    end
  end
end