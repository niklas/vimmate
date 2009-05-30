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
            if ref = index_#{by}[val]
              self.get_iter(ref.path)
            else
              raise("cannot find by #{column}: '\#{val}'")
            end
          end
          def index_#{by}
            @index_#{by} ||= {}
          end
          Signal.on_item_added do |store, iter| # :remember_iter_#{by}
            val = iter[ store.column_id[:#{column}] ]
            store.index_#{by}[val] = Gtk::TreeRowReference.new(store, iter.path)
          end
        EOCODE
      end
    end

  end
end

