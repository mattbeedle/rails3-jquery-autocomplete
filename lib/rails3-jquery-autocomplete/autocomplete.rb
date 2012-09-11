module Rails3JQueryAutocomplete
  module Autocomplete
    def self.included(target)
      target.extend Rails3JQueryAutocomplete::Autocomplete::ClassMethods

      if defined?(Mongoid::Document)
        target.send :include, Rails3JQueryAutocomplete::Orm::Mongoid
      elsif defined?(MongoMapper::Document)
        target.send :include, Rails3JQueryAutocomplete::Orm::MongoMapper
      else
        target.send :include, Rails3JQueryAutocomplete::Orm::ActiveRecord
      end
    end

    #
    # Usage:
    #
    # class ProductsController < Admin::BaseController
    #   autocomplete :brand, :name
    # end
    #
    # This will magically generate an action autocomplete_brand_name, so,
    # don't forget to add it on your routes file
    #
    #   resources :products do
    #      get :autocomplete_brand_name, :on => :collection
    #   end
    #
    # Now, on your view, all you have to do is have a text field like:
    #
    #   f.text_field :brand_name, :autocomplete => autocomplete_brand_name_products_path
    #
    #
    # Yajl is used by default to encode results, if you want to use a different encoder
    # you can specify your custom encoder via block
    #
    # class ProductsController < Admin::BaseController
    #   autocomplete :brand, :name do |items|
    #     CustomJSONEncoder.encode(items)
    #   end
    # end
    #
    module ClassMethods
      def autocomplete(*args)
        options = args.extract_options!
        object = args.shift
        columns = args

        action = options[:action] || "#{object}_#{columns.first}"

        define_method("autocomplete_#{action}") do
          term = params[:term]

          if term && !term.blank?
            items = get_autocomplete_items(relation: get_relation(options), \
              options: options, term: term, columns: columns)
          else
            items = {}
          end

          value = options[:display_value] || columns.first

          render json: json_for_autocomplete(items, columns, value, options[:extra_data])
        end
      end
    end

    # Returns a limit that will be used on the query
    def get_autocomplete_limit(options)
      options[:limit] ||= 10
    end

    def get_relation(options)
      return options[:class_name].to_s.camelize.constantize if options[:class_name]
      return options[:class] if options[:class]

      relation = options[:relation]

      if relation.is_a?(Proc) or relation.is_a?(Symbol)
        return relation.to_proc.call(self)
      elsif relation
        return relation
      else
        raise 'Need to provide :relation, :class_name or :class options'
      end
    end

    #
    # Returns a hash with three keys actually used by the Autocomplete jQuery-ui
    # Can be overriden to show whatever you like
    # Hash also includes a key/value pair for each method in extra_data
    #
    def json_for_autocomplete(items, columns, value, extra_data)
      items.map do |item|
        hash = { "id" => item.id.to_s, "label" => item.send(value), "value" => item.send(value) }
        (columns + Array.wrap(extra_data)).each{ |datum| hash[datum] = item.send(datum) }
        hash
      end
    end
  end
end

