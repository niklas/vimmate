module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include ActiveSupport::Callbacks
    include ActiveTreeStoreColumns
    include TreeStoreExtentions
    column :visible, TrueClass, :virtual => true
    column :object, Object, :virtual => true
    define_callbacks :after_add

    def initialize(opts={})
      super(*self.class.column_classes)
    end

  end
end
