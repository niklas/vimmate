module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include Columns
    column :visible, TrueClass
    column :object, Object

    def initialize(opts={})
      super(self.class.column_classes)
    end
  end
end
