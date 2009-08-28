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
        
        explicit_links = config.whitelisted.select { |x| x.class == Symbol && x.to_s.ends_with?("_restful_url") }
        explicit_links.each { |link| config.whitelisted.delete(link) }
        explicit_links.map! { |link| link.to_s.chomp("_restful_url").to_sym  }
        
        # simple attributes
        resource.values += Restful::Rails.tools.simple_attributes_on(model).map do |key, value|
          convert_to_simple_attribute(key, value, config, published, model)
        end.compact
        
        # has_many, has_one, belongs_to
        resource.values += model.class.reflections.keys.map do |key|
          explicit_link = !!explicit_links.include?(key)
          
          if config.published?(key.to_sym) || explicit_link
            nested_config = config.nested(key.to_sym)
            published << key.to_sym
            
            if has_many?(model, key) && config.expanded?(key, nested)
              convert_to_collection(model, key, nested_config, published) do |key, resources, extended_type|
                Restful.collection(key, resources, extended_type)
              end
            elsif has_one?(model, key) or belongs_to?(model, key)
              if config.expanded?(key, nested) && !explicit_link
                convert_to_collection(model, key, nested_config, published) do |key, resources, extended_type|
                  returning(resources.first) do |res|
                    res.name = key
                  end
                end
              else
                link_to(model, key)
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
        
          explicit_link = !!explicit_links.include?(method_name.to_sym)          
          
          if !published.include?(method_name.to_sym) && (config.published?(method_name.to_sym) || explicit_link)
            value = model.send(method_name.to_sym)
              sanitized_method_name = method_name.tr("!?", "").tr("_", "-").to_sym
              
              if value.is_a? ::ActiveRecord::Base
                if config.expanded?(method_name.to_sym, nested) && !explicit_link
                  returning Restful::Rails.tools.expand(value, config.nested(method_name.to_sym)) do |expanded|
                    expanded.name = sanitized_method_name
                  end
                else
                  Restful.link("#{ sanitized_method_name }-restful-url", Restful::Rails.api_hostname, value ? value.restful_path : "", compute_extended_type(model, method_name.to_sym))
                end
              else
                Restful.attr(sanitized_method_name, value, compute_extended_type(model, method_name))
              end
          end
        end.compact
        
        resource
      end

      def self.has_one?(model, key)
        macro(model, key) == :has_one
      end
      
      def self.has_many?(model, key)
        macro(model, key) == :has_many
      end
      
      def self.belongs_to?(model, key)
        macro(model, key) == :belongs_to
      end

      def self.link_to(model, key)
        value = model.send(key)
        restful_path = value ? value.restful_path : nil
        basename = value ? Restful::Rails.api_hostname : nil
        
        Restful.link("#{ key }-restful-url", basename, restful_path, compute_extended_type(model, key))
      end
      
      def self.convert_to_simple_attribute(key, value, config,  published, model = nil)
        if config.published?(key.to_sym)
          published << key.to_sym
          ext_type = (model ? compute_extended_type(model, key) : value.class.to_s.underscore.to_sym)
          Restful.attr(key.to_sym, value, ext_type)
        end
      end
      
      private
      
        def self.macro(model, key)
          model.class.reflections[key].macro
        end
   
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