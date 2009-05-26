module ActiveWindow
  module ActiveTreeStoreColumns
      def self.included(base)
        base.class_eval do
          class_inheritable_accessor :id
          write_inheritable_attribute :id, {}
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

        def used_columns
          self.class.used_columns
        end

      end

      module ClassMethods
        def column(label,type, opts={})
          return if id.has_key?(label.to_sym) # do not double-define
          index = column_count
          id[label.to_sym] = index
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

        def virtual_column(label, type)
          column label, type, :virtual => true
        end

        # visible vs. virtual
        def used_columns
          columns.reject(&:virtual?)
        end


        def column_count
          columns.size
        end

        def column_classes
          columns.map(&:data_class)
        end
    end
  end
end
