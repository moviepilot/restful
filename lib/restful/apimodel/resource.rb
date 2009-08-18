#
#  Resource model. Something like a DOM model for the api. 
#
module Restful
  module ApiModel
    class Resource < Map
      attr_accessor :base, :path, :url
      
      def initialize(name, url)
        super(name)
        
        self.url = url[:url]
        self.path = url[:path]
        self.base = url[:base]                
        self.type = :resource
      end
      
      def full_url
        base.blank? ? url : "#{ base }#{ path }"
      end
    end
  end
end
