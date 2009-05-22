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
      cols = columns
      cols = cols.except(opts[:except]) if opts.has_key?(:except)
      cols = cols.slice(opts[:only]) if opts.has_key?(:only)
      cols.each do |column|
        treeview.append_column(column.view)
      end
    end

    def populate(array)
      clear
      array.each do |element|
        self.add element  
      end
    end

    def get_object(iter)
      iter[OBJECT]
    end

    def add(object, parent=nil)
      iter = self.append parent
      columns.each do |column|
        iter[column.id] = column.data_value(object) unless column.virtual?
      end
      iter[OBJECT] = object
    end

  end
end
