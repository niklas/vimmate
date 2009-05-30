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
        raise "cannot index by #{column}, it is already applied" if public_instance_methods.include?("find_#{by}")
        class_eval <<-EOCODE
          def find_#{by}!(val)
            find_#{by}(val) || raise("cannot find by #{column}: '\#{val}'")
          end
          def find_#{by}(val)
            if ref = index_#{by}[val]
              self.get_iter(ref.path)
            end
          end
          def remember_iter_#{by}(iter)
            val = iter[ self.class.column_id[:#{column}] ]
            index_#{by}[val] = Gtk::TreeRowReference.new(self, iter.path)
          end
          def index_#{by}
            @index_#{by} ||= {}
          end
          def add_with_index_#{by}(*args)
            iter = add_without_index_#{by}(*args)
            remember_iter_#{by}(iter)
            iter
          end
          alias_method_chain :add, :index_#{by}
        EOCODE
      end
    end

  end
end

