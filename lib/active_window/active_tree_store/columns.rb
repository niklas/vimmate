module ActiveWindow
  module ActiveTreeStoreColumns
      def self.included(base)
        base.class_eval do
          class_inheritable_accessor :column_id
          write_inheritable_attribute :column_id, {}
          class_inheritable_accessor :columns
          write_inheritable_attribute :columns, []
          include InstanceMethods
          extend ClassMethods
        end
      end

      module InstanceMethods
        def columns
          self.class.columns
        end

        def data_columns
          self.class.data_columns
        end

        def visible_columns
          self.class.visible_columns
        end

      end

      module ClassMethods
        # options:
        #   :virtual:  (bool )does not take actual values
        #   :visible:  (bool) should be shown in the view
        def column(label,type, opts={})
          return columns[column_id[label.to_sym]] if column_id.has_key?(label.to_sym) # do not double-define
          opts.reverse_merge!(:visible => true, :virtual => false)
          index = column_count
          column_id[label.to_sym] = index
          col = ActiveColumn.create(index, label, type, opts)
          columns << col
          const_set label.to_s.upcase, index
          class_eval <<-EOCODE
            def self.#{label}_column
              #{index}
            end
          EOCODE
          return col
        end

        def composite_column(label)
          col = ActiveCompositeColumn.new(label)
          yield col
          columns << col
          return col
        end

        def virtual_column(label, type, opts={})
          column label, type, opts.merge(:virtual => true)
        end

        # visible vs. virtual
        def data_columns
          columns.reject(&:virtual?)
        end

        def visible_columns
          columns.select(&:visible?)
        end

        def invisible_columns
          columns.reject(&:visible?)
        end

        def column_count
          columns.size
        end

        def column_classes
          columns.map(&:data_class)
        end

        def setup_column_id_constants
          column_id.each do |sym, index|
            const_set sym.to_s.upcase, index
          end
        end
    end
  end
end
