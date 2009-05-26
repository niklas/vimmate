module ActiveWindow
  module ActiveTreeStoreIndex
    def self.included(base)
      base.class_eval do
        include InstanceMethods
        extend ClassMethods
      end
    end

    module InstanceMethods
    end

    module ClassMethods
      def index_by(column)
        by = %Q~by_#{column}~
        class_eval <<-EOCODE
          def find_#{by}(val)
            @index_#{by}[val] || raise "cannot find by #{column}: '#{val}'"
          end
          def remember_iter_#{by}(iter)
            val = iter[ self.class.id[:#{column}] ]
            @index_#{by}[val] = iter.reference
          end
          after_added :remember_iter_#{by}
        end
        EOCODE
      end
    end

  end
end

