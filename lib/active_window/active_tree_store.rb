module ActiveWindow
  class ActiveTreeStore < Gtk::TreeStore
    include Columns
    column :visible, FalseClass
    column :object, Object
  end
end
