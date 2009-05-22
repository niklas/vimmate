module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include Columns
    column :visible, TrueClass
    column :object, Object

    def initialize(opts={})
      super(self.class.column_classes)
    end
    
    ## associates a Gtk::TreeView widget with self (a tree model). 
    def apply_to_tree(treeview, opts={})
      raise ArgumentError, "please provide a Gtk::TreeView" unless treeview.is_a?(Gtk::TreeView)
      treeview.model = self
      cols = self.class.columns
      # TODO handle :except and :only
      cols 
      cols.each do |column|
        treeview.append_column(column.view)
      end
    end

  end
end
