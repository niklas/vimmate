module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include TreeStoreExtentions
    virtual_column :visible, TrueClass, :visible => false
    virtual_column :object, Object, :visible => false
    define_callbacks :after_add

    def initialize(opts={})
      @initial_add_in_progress = false
      super(*self.class.column_classes)
    end

    # disables some heavy calculations
    def initial_adding
      old_progress = initial_add_in_progress?
      @initial_add_in_progress = true
      yield
      @initial_add_in_progress = old_progress
    end

    def initial_add_in_progress?
      @initial_add_in_progress
    end

  end
end
