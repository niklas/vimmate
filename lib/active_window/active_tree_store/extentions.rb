module ActiveWindow
  module TreeStoreExtentions

    def self.included(base)
      base.class_eval do
        include ActiveSupport::Callbacks
        include ActiveTreeStoreColumns
        include ActiveTreeStoreIndex
      end
    end
    ## associates a Gtk::TreeView widget with self (a tree model). 
    def apply_to_tree(treeview, opts={})
      raise ArgumentError, "please provide a Gtk::TreeView" unless treeview.is_a?(Gtk::TreeView)
      treeview.model = self
      cols = self.class.visible_columns
      cols = cols.except(opts[:except]) if opts.has_key?(:except)
      cols = cols.slice(opts[:only]) if opts.has_key?(:only)
      cols.map(&:view).each do |column|
        treeview.append_column(column)
      end
    end

    # Populare the Tree with an array of objects. The Tree gets cleared first.
    def populate(array)
      clear
      array.each do |element|
        self.add element  
      end
    end

    # The original object for +iter+.
    def get_object(iter)
      iter[ self.class.column_id[:object] ]
    end

    # Add +object+ to tree, give optional +parent+
    def add(object, parent=nil)
      iter = self.append parent
      case object
      when Hash
        update_iter_from_hash iter, object
      else
        update_iter_from_object iter, object
      end
      iter[ self.class.column_id[:object] ] = object
      iter
    end

    # Updates the display in the tree/list of the given object
    def refresh(object)
      each do |model,path,iter| 
        if iter[OBJECT] == object
          update_iter_from_object(iter, object)
          break
        end
      end
    end

    private
    def update_iter_from_object(iter, object)
      data_columns.each do |column|
        iter[column.id] = column.data_value(object)
      end
    end
    def update_iter_from_hash(iter, hash = {})
      hash.symbolize_keys.each do |key,value|
        if id = self.class.column_id[key]
          iter[ id ] = value
        end
      end
    end

    def reference_for(iter)
      Gtk::TreeRowReference.new(self, iter.path)
    end
  end
end
