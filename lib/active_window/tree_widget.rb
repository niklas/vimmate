module ActiveWindow
  class TreeWidget
    include ActiveSupport::Callbacks
    define_callbacks :after_initialize, :before_start
    attr_reader :references
    attr_reader :store, :sort_column, :model, :view
    def initialize(opts = {})
      @references = Hash.new(nil)
      initialize_store
      initialize_model
      initialize_view
      initialize_columns
      run_callbacks :after_initialize
    end
    def save_expands
      @expands = []
      view.map_expanded_rows { |tree_view, path| @expands << path }
      @expands
    end

    def restore_expands
      view.collapse_all if Config[:files_auto_expand_on_filter]
      unless @expands.nil? || @expands.empty?
        @expands.each do |path|
          view.expand_row(path, false)
        end
      end
    end

    def each
      store.each do |model,path,iter|
        yield item_for(iter)
      end
    end

    def selected_row
      if iter = view.selection.selected
        item_for iter
      end
    end

    def item_for(something)
      case something
      when Gtk::TreeRowReference
        iter = store.get_iter(something.path)
        iter.nil? ? nil : item_for(iter)
      when Gtk::TreeIter
        if !something[ListedItem.referenced_type_column].nil?
          build_item(:iter => something)
        end
      when ListedItem
        something
      when Gtk::TreePath
        item_for store.get_iter(something)
      when nil
        raise ArgumentError, "item_for(nil) is not nice, man."
      else
        raise "Gimme a TreeRowRef, TreeIter, TreePath, ListedItem or String (path), no #{something.class} please"
      end
    end

    def build_item(attrs)
      ListedItem.build attrs.merge(:tree => self)
    end

    def create_item(attrs)
      Gtk.queue do
        parent = if (p = attrs.delete(:parent))
                   item_for(p)
                 else
                   nil
                 end
        iter = store.append(parent.try(:iter))
        item = build_item attrs.merge(:iter => iter)
        created_item(item)
      end
    end

    def destroy_item(something)
      Gtk.queue do
        if item = item_for(something) and iter = item.iter
          store.remove iter
        end
      end
    end

    private
    def initialize_view
      @view = Gtk::TreeView.new(model)
      view.selection.mode = Gtk::SELECTION_SINGLE
      view.headers_visible = VimMate::Config[:file_headers_visible]
      view.hover_selection = VimMate::Config[:file_hover_selection]
      view.set_row_separator_func do |model, iter|
        iter[ListedItem.referenced_type_column] == 'Separator'
      end
    end

    def initialize_columns
      column = ListedFile.setup_view_column(Gtk::TreeViewColumn.new)
      view.append_column(column)
    end

    def initialize_store
      @store = Gtk::TreeStore.new *ListedFile.columns_types
      @sort_column = ListedFile.columns_labels.index(:sort) || 0 || 
        raise(ArgumentError, 'no columns specified')
      store.set_sort_column_id(sort_column)
    end

    def initialize_model
      @model = Gtk::TreeModelFilter.new(store)
      model.set_visible_func do |model, iter|
        if !filtered?
          true
        else
          iter[ListedItem.visible_column]
        end
      end
      @filter_string = ""
      @found_count = -1
    end

    def created_item(item)
    end

  end
end
