module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include Columns
    column :visible, TrueClass, :virtual => true
    column :object, Object, :virtual => true

    def initialize(opts={})
      super(*self.class.column_classes)
    end
    
    ## associates a Gtk::TreeView widget with self (a tree model). 
    def apply_to_tree(treeview, opts={})
      raise ArgumentError, "please provide a Gtk::TreeView" unless treeview.is_a?(Gtk::TreeView)
      treeview.model = self
      cols = used_columns
      cols = cols.except(opts[:except]) if opts.has_key?(:except)
      cols = cols.slice(opts[:only]) if opts.has_key?(:only)
      cols.each do |column|
        treeview.append_column(column.view)
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
      iter[OBJECT]
    end

    # Add +object+ to tree, give optional +parent+
    def add(object, parent=nil)
      iter = self.append parent
      used_columns.each do |column|
        iter[column.id] = column.data_value(object)
      end
      iter[OBJECT] = object
    end

    # Updates the display in the tree/list of the given object
    def refresh(object)
      each do |model,path,iter| 
        if iter[OBJECT] == object
          used_columns.each do |column|
            set_value(iter, column.id, column.data_value(object))
          end
          break
        end
      end
    end

  end
end
