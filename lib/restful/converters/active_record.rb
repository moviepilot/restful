#
#  Converts an ActiveRecord model into an ApiModel
#
module Restful
  module Converters
    class ActiveRecord
      def self.convert(model, config, options = {})

        published = []
        nested = config.nested?

        resource = Restful.resource(
          model.class.to_s.tableize.demodulize.singularize, { 
            :base => Restful::Rails.api_hostname, 
            :path => model.restful_path,
            :url => model.restful_url
        })
                
        # simple attributes
        resource.values += Restful::Rails.tools.simple_attributes_on(model).map do |attribute|
          key, value = attribute
          
          if config.published?(key.to_sym)
            published << key.to_sym
            Restful.attr(key.to_sym, value, compute_extended_type(model, key))
          end
        end.compact

        # has_many, has_one
        resource.values += model.class.reflections.keys.map do |key|
          if config.published?(key.to_sym)
            
            # grab the associated resource(s) and run them through conversion
            nested_config = config.nested(key.to_sym)
            published << key.to_sym
            
            if model.class.reflections[key].macro == :has_many && !nested
              convert_to_collection(model, key, nested_config, published) do |key, resources, extended_type|
                Restful.collection(key, resources, extended_type)
              end
            elsif model.class.reflections[key].macro == :has_one or model.class.reflections[key].macro == :belongs_to

              if(config.expanded?(key, nested)) 
                convert_to_collection(model, key, nested_config, published) do |key, resources, extended_type|
                  returning(resources.first) do |res|
                    res.name = key
                  end
                end
              else
          
                value = model.send(key)
                restful_path = value ? value.restful_path : nil
                basename = value ? Restful::Rails.api_hostname : nil
                
                Restful.link("#{ key }-restful-url", basename, restful_path, compute_extended_type(model, key))
              end
            end
          end
        end.compact

        # Links
        if model.class.apiable_association_table
          resource.values += model.class.apiable_association_table.keys.map do |key|
            if config.published?(key.to_sym)
              published << key.to_sym
              base, path = model.resolve_association_restful_url(key)
              Restful.link(key.to_sym, base, path, compute_extended_type(model, key))
            end
          end.compact
        end
        
        # public methods
        resource.values += (model.public_methods - Restful::Rails.tools.simple_attributes_on(model).keys.map(&:to_s)).map do |method_name|
          if config.published?(method_name.to_sym) and not published.include?(method_name.to_sym)
            value = model.send(method_name.to_sym)
              sanitized_method_name = method_name.tr("!?", "").tr("_", "-").to_sym
              
              if value.is_a? ::ActiveRecord::Base
                if config.expanded?(method_name.to_sym, nested)
                  returning Restful::Rails.tools.expand(value, config.nested(method_name.to_sym)) do |expanded|
                    expanded.name = sanitized_method_name
                  end
                else
                  Restful.link("#{ sanitized_method_name }-restful-url", Restful::Rails.api_hostname, value ? value.restful_path : "", compute_extended_type(model, key))
                end
              else
                Restful.attr(sanitized_method_name, value, compute_extended_type(model, method_name))
              end
          end
        end.compact
        
        resource
      end
      
      private
   
        def self.convert_to_collection(model, key, nested_config, published)
          if resources = Restful::Rails.tools.convert_collection_to_resources(model, key, nested_config)
            yield key.to_sym, resources, compute_extended_type(model, key)
          else
            published << key.to_sym
            Restful.attr(key.to_sym, nil, :notype)
          end
        end
        
        def self.compute_extended_type(record, attribute_name)
          type_symbol = :yaml if record.class.serialized_attributes.has_key?(attribute_name)
          
          if column = record.class.columns_hash[attribute_name]
            type_symbol = column.send(:simplified_type, column.sql_type)
          else

            type_symbol = record.send(attribute_name).class.to_s.underscore.to_sym
          end

          case type_symbol
            when :text
              :string
            when :time 
              :datetime
            when :date
              :date
            else
              type_symbol
            end
        end
    end
  end
end