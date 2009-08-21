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
        Yajl::Encoder.encode HashSerializer.new.serialize(resource, options)
      end
    end
  end
end