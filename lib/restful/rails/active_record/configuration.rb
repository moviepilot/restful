#
#  Configuration options for restful. 
#
module Restful
  module Rails
    module ActiveRecord
      module Utils
        
        def self.get_includes(config)
          if config && config.is_a?(Hash) && config.keys.size == 1 && includes = config[:include] 
            add_to_whitelist = [*includes].map { |el| el.is_a?(String) ? el.to_sym : el  }
            return nil, add_to_whitelist
          else
            return config, []
          end
        end
        
        def self.convert_to_single_resource(config_parameter, el)
          config = if config_parameter
            returning Configuration::Config.new(config_parameter) do |c|
              config, includes = Utils.get_includes(config_parameter)
              c.whitelisted += el.class.restful_config.whitelisted unless config
              c.whitelisted += includes unless includes.blank?
            end
          else
            el.class.restful_config
          end
          
          Restful::Converters::ActiveRecord.convert(el, config)
        end  
      end
      
      module Configuration
        def self.included(base)
          base.send :class_inheritable_accessor, :restful_config
          base.restful_config = Config.new
          base.send :include, ResourceInstanceMethods
          base.send :include, CommonInstanceMethods
          base.extend(ClassMethods)
        end
        
        module ClassMethods
          
          #
          #  In the form: 
          #
          #    Person.restful_publish(:name, :pets => [:name, :species])
          #
          #  If pet already has configured the api with restful_publish, you would
          #  get the default nested attributes. In the above example, these would be
          #  overriden. 
          #
          def restful_publish(*fieldnames) # declarative setter method
            self.restful_config = Restful.cfg(*fieldnames)
          end
        end
        
        module CommonInstanceMethods
          #
          #  converts this AR object to an apimodel object. per default, only the
          #  attributes in self.class.restful_config are shown. this can be overriden
          #  by passing in something like @pet.to_restful(:name, :species).
          #
          def to_restful(config_parameter = nil)
            config, add_to_whitelist = Utils.get_includes(config_parameter)
            
            config ||= self.class.restful_config.clone if self.class.respond_to?(:restful_config)
            config ||= []
            
            if config && !config.is_a?(Config)
             config = Config.new(config)
            end
            
            if self.class.respond_to?(:restful_config)
              config.whitelisted = Array.new(self.class.restful_config.whitelisted) if config.whitelisted.empty?
              config.restful_options.merge! self.class.restful_config.restful_options
            end
            
            config.whitelisted += add_to_whitelist
            config.whitelisted = config.whitelisted.uniq
            
            # array
            result = if self.is_a?(Array)
              element_name = if fst = self.first
                fst.class.respond_to?(:base_class) ? 
                  fst.class.base_class.to_s.tableize :
                  fst.class.to_s.pluralize
              elsif self.respond_to?(:name)
                self.name
              else
                "nil-classes"
              end

              elements = self.map do |el|
                raise TypeError.new("Not all array elements respond to #to_restful. ") unless el.respond_to?(:to_restful)
                Utils.convert_to_single_resource(config_parameter, el)
              end
              
              returning Restful.collection(element_name, elements, :array) do |collection|
                collection.total_entries = self.total_entries if self.respond_to?(:total_entries)
              end
                        
            elsif self.is_a?(Hash)
              
              elements = self.map do |k,v|
                value = if v.respond_to?(:to_restful) and v.class.respond_to?(:restful_config)
                  Utils.convert_to_single_resource(config_parameter, v)
                else
                  v.respond_to?(:to_restful) ? v.to_restful : v
                end
                Restful::ApiModel::Attribute.new(k, value, :map)
              end
              
              map = Restful::ApiModel::Map.new("hash")
              map.values =  elements
              map
            else
              Restful::Converters::ActiveRecord.convert(self, config)
            end  
            
            # breakpoint
            result
          end
                    
          # FIXME: read Restful::Serializers::Base.serializers. Load order problems?
          [:atom_like, :hash, :json, :params, :xml].each do |format|
            define_method("to_restful_#{ format }") do |*args|
              self.to_restful(*args).serialize(format)
            end            
          end
        end
    
        module ResourceInstanceMethods
                    
          # simple method through which a model should know it's own name. override this where necessary. 
          def restful_url(url_base = Restful::Rails.api_hostname)
            "#{ url_base }#{ restful_path }"
          end
          
          def restful_path
            "/#{ self.class.base_class.to_s.tableize }/#{ self.to_param }"
          end
        end
        
        class Config # configures what attributes are exposed to the api. for a single resource.
          
          attr_accessor :whitelisted, :restful_options
          
          def initialize(*fields) # set; eg :name, :pets => [:name, :species]
            @whitelisted, @restful_options = split_into_whitelist_and_restful_options([fields].flatten.compact)
          end

          def published?(key)
            @whitelisted.include?(key) || !!@whitelisted.select { |field| field.is_a?(Hash)  && field.keys.include?(key) }.first
          end

          def expanded?(key, nested = false) # if nothing was set, this defaults to true. 
            force_expanded?(key) || (@restful_options[:expansion] != :collapsed && !nested)
          end
          
          def force_expanded?(key)
            force = [*@restful_options[:force_expand]]
            force.include?(key)
          end

          def nested?
            !!restful_options[:nested]
          end

          def nested(key)
            definition = @whitelisted.select { |field| field.is_a?(Hash)  && field.keys.include?(key) }.first
            Config.new((definition[key] if definition))
          end

          private
                    
            def split_into_whitelist_and_restful_options(array)
              options = {}
        
              return array.map do |el|
                if el.is_a? Hash
                  el = el.clone
                  deleted = el.delete(:restful_options) 
                  options.merge!(deleted) if deleted
                  el = nil if el == {}
                end
              
                el
              end.compact, options
            end
            
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, Restful::Rails::ActiveRecord::Configuration
Array.send :include, Restful::Rails::ActiveRecord::Configuration::CommonInstanceMethods
Hash.send :include, Restful::Rails::ActiveRecord::Configuration::CommonInstanceMethods