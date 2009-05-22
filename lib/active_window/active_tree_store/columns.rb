module ActiveWindow
  class ActiveTreeStore
    module Columns
      def self.included(base)
        base.class_eval do
          class_inheritable_accessor :columns
          write_inheritable_attribute :columns, {}
          class_inheritable_accessor :column_definitions
          write_inheritable_attribute :column_definitions, []
          include InstanceMethods
          extend ClassMethods
        end
      end

      module InstanceMethods
      end

      module ClassMethods
        def column(label,type)
          return if columns.has_key?(label.to_sym) # do not double-define
          index = column_count
          columns[label.to_sym] = index
          column_definitions << [label.to_sym, type]
          const_set label.to_s.upcase, index
          class_eval <<-EOCODE
            def self.#{label}_column
              #{index}
            end
          EOCODE
        end

        def column_count
          read_inheritable_attribute(:columns).size
        end
      end
    end
  end
end
