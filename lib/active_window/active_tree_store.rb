module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include ActiveTreeStoreColumns
    include TreeStoreExtentions
    column :visible, TrueClass, :virtual => true
    column :object, Object, :virtual => true

    def initialize(opts={})
      super(*self.class.column_classes)
    end

  end
end
