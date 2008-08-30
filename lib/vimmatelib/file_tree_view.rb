require 'gtk2'

module VimMate
  # Type of row: file
  TYPE_FILE = 0
  # Type of row: directory
  TYPE_DIRECTORY = 1
  # Type of row: separator
  TYPE_SEPARATOR = 2
  # Type of row: message ("nothing found")
  TYPE_MESSAGE = 3
  class TreeViewRow
    attr_reader :tree, :iter
    def initialize(iter,tree)
      @iter = iter
      @tree = tree
    end

    def method_missing(meth, *args, &block)
      tree_columns_labels = tree.columns.collect { |c| c[0] }
      if id = tree_columns_labels.index(meth.to_sym)
        iter[id]
      elsif meth.to_s =~ /^(.*)=$/ 
        if id = tree_columns_labels.index($1.to_sym)
          iter[id] = args.first
        else
          raise NoMethodError, "illegal setter: #{meth}"
        end
      else
        raise NoMethodError, "could not auto-respond to #{meth}"
      end
    end

    def show!
      self.visible = true
      if directory? and Config[:file_directory_separator]
        if iter.next!
          tree.row_for_iter(iter).show!
        end
      end
    end
    def hide!
      self.visible = false
      if directory? and Config[:file_directory_separator]
        if iter.next!
          tree.row_for_iter(iter).hide!
        end
      end
    end

    def file?
      referenced_type == TYPE_FILE
    end
    def directory?
      referenced_type == TYPE_DIRECTORY
    end
    def file_or_directory?
      file? || directory?
    end
    def separator?
      referenced_type == TYPE_SEPARATOR
    end
    def message?
      referenced_type == TYPE_MESSAGE
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
    column :referenced_type, Fixnum
    column :name, String
    alias :filter :filter_string
    def initialize(*args)
      @store = Gtk::TreeStore.new *@@columns.collect{|c| c[1] }
      @sort_column = @@columns.index(:sort) || 0 || 
        raise(ArgumentError, 'no columns specified')
      @store.set_sort_column_id(sort_column)
      @message_row = store.append(nil)
        @message_row[REFERENCED_TYPE] = TYPE_MESSAGE
        @message_row[NAME] = "nothing found"
      @model = Gtk::TreeModelFilter.new(@store)
      @filter_string = ""
      @found_count = -1
      model.set_visible_func do |model,row|
        if row[REFERENCED_TYPE] == TYPE_MESSAGE
          @found_count == 0
        elsif !filter?
          true
        elsif row[REFERENCED_TYPE] == TYPE_SEPARATOR
          row[VISIBLE]
        else
          row[VISIBLE]
        end
      end

      @view = Gtk::TreeView.new(@model)
      view.selection.mode = Gtk::SELECTION_SINGLE
      view.headers_visible = Config[:file_headers_visible]
      view.hover_selection = Config[:file_hover_selection]
      view.set_row_separator_func do |model, iter|
        iter[REFERENCED_TYPE] == TYPE_SEPARATOR
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
      @found_count = -1
      model.refilter
      view.collapse_all if Config[:files_auto_expand_on_filter]
      filter
    end

    # Filter tree view so only directories and separators with matching
    # elements are set visible
    def apply_filter
      visible_path = Hash.new(false)
      @found_count = 0

      store.each do |model,path,iter|
        row = row_for_iter(iter)
        if row.file? # show files if name matches filter
          if row_visible? row
            @found_count += 1
            # recursivly show parent folders
            begin
              visible_path[path.to_s] = true
            end while path.up!
          end
        end
      end

      store.each do |model,path,iter|
        row = row_for_iter(iter)
        if visible_path[path.to_s]
          row.show!
        else
          row.hide!
        end
      end

      model.refilter
      view.expand_all if Config[:files_auto_expand_on_filter]
    end

    # if NAME contains @filter_string
    def iter_visible?(iter)
      if filter?
        row_visible? row_for_iter(iter)
      else
        true
      end
    end
    def row_visible? row
      row.name && row.name.index(filter_string)
    end
  end
  class FileTreeView < TreeView
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
        end
      end
      listed_tree.after_removed do |file_or_directory|
        Gtk.queue do
          remove_file_from_tree(file_or_directory)
        end
      end
      listed_tree.after_refreshed do |file_or_directory|
        Gtk.queue do
          refresh_row_for(file_or_directory)
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
        new_row[REFERENCED_TYPE] = TYPE_SEPARATOR
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
        if iter.next! and iter[REFERENCED_TYPE] == TYPE_SEPARATOR
          to_remove << iter
        end
      end
      to_remove.each do |iter|
        store.remove(iter)
      end
    end

    # Called when the status of the file has changed
    def refresh_row_for(file)
      if row = file.row
        row[ICON] = file.icon
        row[STATUS] = file.status_text if Config[:files_show_status]
        row[VISIBLE] = iter_visible? row
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
        row[REFERENCED_TYPE] = TYPE_DIRECTORY
      else
        row[SORT] = "2-#{file.path}-1"
        row[REFERENCED_TYPE] = TYPE_FILE
      end
      row[VISIBLE] = iter_visible? row
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
