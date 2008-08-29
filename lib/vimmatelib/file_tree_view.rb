require 'gtk2'

module VimMate
  # Type of row: file
  TYPE_FILE = 0
  # Type of row: directory
  TYPE_DIRECTORY = 1
  # Type of row: separator
  TYPE_SEPARATOR = 2
  class TreeViewRow
    attr_reader :tree, :iter
    def initialize(iter,tree)
      @iter = iter
      @tree = tree
    end

    def method_missing(meth)
      tree_columns_labels = tree.columns.collect { |c| c[0] }
      if id = tree_columns_labels.index(meth.to_sym)
        iter[id]
      else
        raise NoMethodError, "could not auto-respond to #{meth}"
      end
    end
  end
  class TreeView
    @@columns = []
    def self.column(label,type)
      @@columns << [label.to_sym, type]
      class_eval %Q[#{label.to_s.upcase} = #{@@columns.length-1}]
    end
    def columns
      @@columns
    end

    attr_reader :store, :sort_column, :model, :view
    attr_reader :filter_string
    column :sort, String
    column :visible, FalseClass
    column :type, Fixnum
    alias :filter :filter_string
    def initialize(*args)
      @store = Gtk::TreeStore.new *@@columns.collect{|c| c[1] }
      @sort_column = @@columns.index(:sort) || 0 || 
        raise(ArgumentError, 'no columns specified')
      @store.set_sort_column_id(sort_column)
      @model = Gtk::TreeModelFilter.new(@store)
      @filter_string = ""
      model.set_visible_func do |model,row|
        if !filter?
          true
        elsif row[TYPE] == TYPE_SEPERATOR
          false
        else
          row[VISIBLE]
        end
      end

      @view = Gtk::TreeView.new(@model)
      view.selection.mode = Gtk::SELECTION_SINGLE
      view.headers_visible = Config[:file_headers_visible]
      view.hover_selection = Config[:file_hover_selection]
      view.set_row_separator_func do |model, iter|
        iter[TYPE] == TYPE_SEPARATOR
      end
    end

    def filter_string=(new_filter_string)
      if new_filter_string.empty?
        clear_filter
      else
        @filter_string = new_filter_string
        apply_filter
      end
    end
    alias :filter= :filter_string=

    def filter?
      !filter_string.nil? and !filter_string.empty?
    end

    protected
    def row_for_iter(iter)
      if iter
        TreeViewRow.new(iter, self)
      else
        raise ArgumentError, "no iter/row given"
      end
    end

    private
    # Clear the filter, show all rows in tree and try to re-construct
    # the previous collapse state
    def clear_filter
      @filter_string = ''
      model.refilter
      view.collapse_all if Config[:files_auto_expand_on_filter]
      filter
    end

    # Filter tree view so only directories and separators with matching
    # elements are set visible
    def apply_filter
      visible_path = Hash.new(false)

      store.each do |model,path,iter|
        if iter[NAME] and iter[TYPE] == TYPE_FILE
          # if NAME contains @filter_string
          if iter[VISIBLE] = iter[NAME].index(filter_string)
            begin
              visible_path[path.to_s] = true
            end while path.up!
          end
        else
          iter[VISIBLE] = true
          if iter[TYPE] == TYPE_SEPARATOR
            visible_path[path.to_s] = true
          end
        end
      end

      store.each do |model,path,iter|
        if not visible_path[path.to_s]
          iter[VISIBLE] = false
          if iter[TYPE] == TYPE_DIRECTORY and Config[:file_directory_separator]
            if iter.next!
              iter[VISIBLE] = false
            end
          end
        end
      end

      model.refilter
      view.expand_all if Config[:files_auto_expand_on_filter]
    end
  end
  class FileTreeView < TreeView
    column :name, String
    column :path, String
    column :icon, Gdk::Pixbuf
    column :status, String
    attr_reader :listed_tree
    def initialize(new_listed_tree = ListedTree)
      @listed_tree = new_listed_tree
      super
      configure_columns
      # Register to receive a signal when a file is added, removed
      # or refreshed
      listed_tree.after_added do |file_or_directory|
        Gtk.queue do
          add_to_tree(file_or_directory)
          model.refilter
        end
      end
      listed_tree.after_removed do |file_or_directory|
        Gtk.queue do
          remove_file_from_tree(file_or_directory)
          model.refilter
        end
      end
      listed_tree.after_refreshed do |file_or_directory|
        Gtk.queue do
          refresh_row_for(file_or_directory)
          model.refilter
        end
      end
    end

    def full_path_for_row(row)
      File.join File.dirname(row[PATH]), row[NAME]
    end

    def find_row_by_iter_path(given_path)
      if iter = model.get_iter(given_path)
        row_for_iter(iter)
      end
    end

    def selected_row
      if iter = view.selection.selected
        row_for_iter(iter)
      end
    end

    # Add a file to the tree
    def add_to_tree(file)
      parent = file.parent ? file.parent.row : nil
      # If we need a separator and it's a directory, we add it
      if Config[:file_directory_separator] and file.instance_of? ListedDirectory
        new_row = store.append(parent)
        new_row[TYPE] = TYPE_SEPARATOR
        new_row[SORT] = "1-#{file.path}-2"
      end
      # Add the row for the file
      new_row = store.append(parent)
      file.row = new_row # so will find it later fast
      fill_row_for(file)
    end

    # A file is removed. Find it and remove it
    def remove_file_from_tree(file)
      to_remove = []
      if iter = file.row
        to_remove << iter
        if iter.next! and iter[TYPE] == TYPE_SEPARATOR
          to_remove << iter
        end
      end
      to_remove.each do |iter|
        store.remove(iter)
      end
    end

    # Called when the status of the file has changed
    def refresh_row_for(file)
      if iter = file.row
        iter[ICON] = file.icon
        iter[STATUS] = file.status_text if Config[:files_show_status]
      end
    end
    def fill_row_for(file)
      row = file.row
      row[NAME] = file.name
      row[PATH] = file.path
      row[ICON] = file.icon
      row[STATUS] = file.status_text if Config[:files_show_status]
      if file.instance_of? ListedDirectory
        row[SORT] = "1-#{file.path}-1"
        row[TYPE] = TYPE_DIRECTORY
      else
        row[SORT] = "2-#{file.path}-1"
        row[TYPE] = TYPE_FILE
      end
    end

    private
    def configure_columns
      column = Gtk::TreeViewColumn.new
      column.title = "Files"

      # Icon
      icon_cell_renderer = Gtk::CellRendererPixbuf.new
      column.pack_start(icon_cell_renderer, false)
      column.set_attributes(icon_cell_renderer, :pixbuf => ICON)

      # File name
      text_cell_renderer = Gtk::CellRendererText.new
      if Config[:files_use_ellipsis]
        text_cell_renderer.ellipsize = Pango::Layout::EllipsizeMode::MIDDLE
      end
      column.pack_start(text_cell_renderer, true)
      column.set_attributes(text_cell_renderer, :text => NAME)
      
      # Status
      if Config[:files_show_status]
        text_cell_renderer2 = Gtk::CellRendererText.new
        if Config[:files_use_ellipsis]
          text_cell_renderer2.ellipsize = Pango::Layout::EllipsizeMode::END
        end
        column.pack_start(text_cell_renderer2, true)
        column.set_attributes(text_cell_renderer2, :text => STATUS)
      end
      
      view.append_column(column)
    end
  end
end
