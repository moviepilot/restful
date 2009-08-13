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
            
            params[hashify_key(value.name)] = array
          elsif value.type == :link
            params[hashify_key(value.name)] = Restful::Rails.tools.dereference(value.value)
          elsif value.type == :resource
            params[hashify_key(value.name)] = serialize(value)
          else # plain ole
            string_value = case value.extended_type
              when :datetime
                value.value.xmlschema
              when :date
                value.value.to_s(:db)
              else
                value.value
            end

            params[hashify_key(value.name)] = formatted_value(string_value)
          end
        end
        
        params["restful_url"] = resource.full_url
        params
      end
      
      private
        def hashify_key(original_key)
          original_key.to_s.tr("-", "_").to_sym
        end
    end
  end
end