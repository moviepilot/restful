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
        hasher = Restful::Serializers::HashSerializer.new
        hash = hasher.serialize(resource, options)
        Yajl::Encoder.encode(hash)
      end
    end
  end
end