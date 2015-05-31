module Rails3JQueryAutocomplete
  module Orm
    module ActiveRecord
      def get_autocomplete_order(method, options, model=nil)
        order = options[:order]

        table_prefix = model ? "#{model.table_name}." : ""
        order || "#{table_prefix}#{method} ASC"
      end

      def get_autocomplete_items(parameters)
        relation  = parameters[:relation]
        term      = parameters[:term]
        columns   = parameters[:columns]
        options   = parameters[:options]
        scopes    = Array(options[:scopes])
        where     = options[:where]
        limit     = get_autocomplete_limit(options)
        order     = get_autocomplete_order(columns.first, options, relation)


        items = relation.scoped

        scopes.each { |scope| items = items.send(scope) } unless scopes.empty?

        items = items.select(get_autocomplete_select_clause(relation, columns, options)) unless options[:full_model]
        items = items.where(get_autocomplete_where_clause(relation, term, columns, options))
        items = items.limit(limit).order(order)
        items = items.where(where) unless where.blank?

        items
      end

      def get_autocomplete_select_clause(model, columns, options)
        table_name = model.table_name
        columns += [model.primary_key]
        columns += Array.wrap(options[:extra_data])
        columns.map{ |column_name| "#{table_name}.#{column_name}" }
      end

      def get_autocomplete_where_clause(model, term, columns, options)
        table_name = model.table_name
        is_full_search = options[:full]
        like_clause = (postgres?(model) ? 'ILIKE' : 'LIKE')
        sql = columns.map{ |column_name| "LOWER(#{table_name}.#{column_name}) #{like_clause} :search" }.join(' OR ')
        [sql, search: "#{(is_full_search ? '%' : '')}#{term.downcase}%"]
      end

      def postgres?(model)
        # Figure out if this particular model uses the PostgreSQL adapter
        model.connection.class.to_s.match(/PostgreSQLAdapter/)
      end
    end
  end
end
