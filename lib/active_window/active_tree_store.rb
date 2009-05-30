module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include TreeStoreExtentions
    virtual_column :visible, TrueClass, :visible => false
    virtual_column :object, Object, :visible => false
    define_callbacks :after_add

    def initialize(opts={})
      super(*self.class.column_classes)
    end

  end
end
