=begin
= VimMate: Vim graphical add-on
Copyright (c) 2006 Guillaume Benny

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end

require 'gtk2'
require 'set'
require 'thread'
require 'vimmatelib/config'
require 'vimmatelib/files'
require 'vimmatelib/icons'
require 'vimmatelib/search_window'

module VimMate

  # The window that contains the file tree
  class FilesWindow

    # Column for the file name
    NAME = 0
    # Column for the full path of the file
    PATH = 1
    # Column for the icon of the file
    ICON = 2
    # Column used to sort the files
    SORT = 3
    # Column used to store the type of row
    TYPE = 4
    # Column used to store the status of the file
    STATUS = 5
    # Visiblity of row
    VISIBLE = 6    
    # Type of row: file
    TYPE_FILE = 0
    # Type of row: directory
    TYPE_DIRECTORY = 1
    # Type of row: separator
    TYPE_SEPARATOR = 2

    # Create a FilesWindow
    def initialize(exclude_file_list = [])
      @open_signal = Set.new
      @menu_signal = Set.new
      @expander_signal = Set.new

      @filter_string = ""
      
      # Tree Store: Filename, Full path, Icon, Sort, Type, Status
      @gtk_tree_store = Gtk::TreeStore.new(String,
                                           String,
                                           Gdk::Pixbuf,
                                           String,
                                           Fixnum,
                                           String,
                                           FalseClass)
      @gtk_tree_store.set_sort_column_id(SORT)

      # Filtered Tree Store
      @gtk_filtered_tree_model = Gtk::TreeModelFilter.new(@gtk_tree_store)
      @gtk_filtered_tree_model.set_visible_func do |model, iter|
        if @filter_string.nil? or @filter_string.empty?
          true
        else
          iter[VISIBLE]
        end
      end
      
      # Tree View
      @gtk_tree_view = Gtk::TreeView.new(@gtk_filtered_tree_model)
      @gtk_tree_view.selection.mode = Gtk::SELECTION_SINGLE
      @gtk_tree_view.headers_visible = Config[:file_headers_visible]
      @gtk_tree_view.hover_selection = Config[:file_hover_selection]

      # Double-click, Enter, Space: Signal to open the file
      @gtk_tree_view.signal_connect("row-activated") do |view, path, column|
        path = @gtk_filtered_tree_model.get_iter(path)[PATH]
        @open_signal.each do |signal|
          signal.call(path,
                      Config[:files_default_open_in_tabs] ? :tab_open : :open)
        end
      end

      # Left-click: Select and Signal to open the menu
      @gtk_tree_view.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          path = @gtk_tree_view.get_path_at_pos(event.x, event.y)
          @gtk_tree_view.selection.select_path(path[0]) if path

          selected = @gtk_tree_view.selection.selected
          if selected
            @menu_signal.each do |signal|
              signal.call(selected[PATH])
            end
          end
        end
      end

      # Create a label to show the path of the file
      gtk_label = Gtk::Label.new
      gtk_label.ellipsize = Pango::Layout::EllipsizeMode::START

      # When a selection is changed in the tree view, we change the label
      # to show the path of the file
      @gtk_tree_view.selection.signal_connect("changed") do
        gtk_label.text = ""
        next if (selected_row = @gtk_tree_view.selection.selected).nil?
        gtk_label.text = File.join(File.dirname(selected_row[PATH]), selected_row[NAME])
      end
      
      # Same thing as Left-click, but with the keyboard
      @gtk_tree_view.signal_connect("popup_menu") do
        selected = @gtk_tree_view.selection.selected
        if selected
          @menu_signal.each do |signal|
            signal.call(selected[PATH])
          end
        end
      end

      # Separator between directories
      @gtk_tree_view.set_row_separator_func do |model, iter|
        iter[TYPE] == TYPE_SEPARATOR
      end

      # Add the columns
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
      
      @gtk_tree_view.append_column(column)
      
      # Put the tree view in a scroll window
      @gtk_scrolled_window = Gtk::ScrolledWindow.new
      @gtk_scrolled_window.set_policy(Gtk::POLICY_AUTOMATIC,
                                      Gtk::POLICY_AUTOMATIC)
      @gtk_scrolled_window.add(@gtk_tree_view)
      
      # Set the default size for the file list
      @gtk_scrolled_window.set_size_request(Config[:files_opened_width], -1)

      # Create a box to filter the list
      gtk_filter_box = Gtk::HBox.new
      gtk_filter_box.pack_start(gtk_filter_button = Gtk::ToggleButton.new("Filter"), false, false)
      gtk_filter_box.pack_start(@gtk_file_filter_entry = Gtk::Entry.new, true, true)
      changed_lambda = lambda do
        if gtk_filter_button.active?
          self.filter = @gtk_file_filter_entry.text
        else
          self.clear_filter
        end
      end
      @gtk_file_filter_entry.signal_connect("changed", &changed_lambda)
      gtk_filter_button.signal_connect("toggled", &changed_lambda)
      gtk_filter_button.active = Config[:files_filter_active]
      gtk_filter_box.spacing = 10
      gtk_filter_box.border_width = 10

      # Create the file tree
      initialize_file_tree(exclude_file_list)
      
      gtk_top_box = Gtk::VBox.new
      gtk_top_box.pack_start(gtk_filter_box, false, false)
      gtk_top_box.pack_start(@gtk_scrolled_window, true, true)
      gtk_top_box.pack_start(gtk_label, false, false)

      # Create the search file list if it's enabled
      if Config[:files_use_search]
        @gtk_paned_box = Gtk::VPaned.new
        @gtk_paned_box.add(gtk_top_box)
        @gtk_paned_box.add((@search_window = SearchWindow.new(@file_tree)).gtk_window)
        @gtk_paned_box.position = Config[:files_search_separator_position]

        # Set the signals for the search window
        @search_window.add_open_signal do |path, kind|
          @open_signal.each do |signal|
            signal.call(path, kind)
          end
        end
        @search_window.add_menu_signal do |path|
          @menu_signal.each do |signal|
            signal.call(path)
          end
        end
      end

      
      @gtk_expander = Gtk::Expander.new("File list")
      @gtk_expander.expanded = Config[:files_expanded]
      if Config[:files_use_search]
        @gtk_expander.add(@gtk_paned_box)
      else
        @gtk_expander.add(gtk_top_box)
      end
      @gtk_expander.signal_connect("notify::expanded") do
        @expander_signal.each do |signal|
          signal.call(@gtk_expander.expanded?)
        end
      end

      gtk_window.border_width = 5

      @file_tree_mutex = Mutex.new
    end

    # Recursively add a path at the root of the tree
    def add_path(path)
      @file_tree_mutex.synchronize do
        @file_tree.add_path(path)
      end
      self
    end

    # The "window" for this object
    def gtk_window
      @gtk_expander
    end

    # Refresh the file list
    def refresh
      do_refresh
      self
    end

    # Get the filter: files must contain this string
    def filter
      @filter_string
    end

    # Set a filter: files must contain this string
    def filter=(filter)
      if filter.empty?
        clear_filter
        return
      end
      @filter_string = filter
      
      # Filter tree view so only directories and separators with matching
      # elements are set visible
      visible_path = Hash.new(false)
      
      @gtk_tree_store.each do |model,path,iter|
        if iter[NAME] and iter[TYPE] == TYPE_FILE
          if iter[VISIBLE] = iter[NAME].index(@filter_string)
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

      @gtk_tree_store.each do |model,path,iter|
        if not visible_path[path.to_s]
          iter[VISIBLE] = false
          if iter[TYPE] == TYPE_DIRECTORY and Config[:file_directory_separator]
            if iter.next!
              iter[VISIBLE] = false
            end
          end
        end
      end

      @gtk_filtered_tree_model.refilter
      @gtk_tree_view.expand_all if Config[:files_auto_expand_on_filter]
    end

    # Clear the filter
    def clear_filter
      @filter_string = ""
      @gtk_filtered_tree_model.refilter
      @gtk_tree_view.collapse_all if Config[:files_auto_expand_on_filter]
      filter
    end

    # Set the focus to the file filter
    def focus_file_filter
      @gtk_file_filter_entry.has_focus = true if @gtk_file_filter_entry
    end

    # Set the focus to the file list
    def focus_file_list
      @gtk_tree_view.has_focus = true if @gtk_tree_view
    end

    # Set the focus to the search file list
    def focus_file_search
      @search_window.focus_file_search if @search_window
    end

    # Expand the first row of the file tree
    def expand_first_row
      @gtk_tree_view.collapse_all
      @gtk_tree_view.expand_row(Gtk::TreePath.new("0"), false)
    end

    # Add a block that will be called when the user choose to open a file
    # The block take two argument: the path to the file to open, and a
    # symbol to indicate the kind: :open, :split_open, :tab_open
    def add_open_signal(&block)
      @open_signal << block
    end

    # Add a block that will be called when the user choose to open the
    # menu. The block takes one argument: the path to the file to open.
    def add_menu_signal(&block)
      @menu_signal << block
    end

    # Add a block that will be called when the user choose to expand or
    # close the expander. The block takes one argument: if the expander
    # is opened or closed
    def add_expander_signal(&block)
      @expander_signal << block
    end

    # Indicates that the initial file adding is going on. The timer to refresh
    # the list is started after the initial add.
    def initial_add(&block)
      @file_tree.initial_add(&block)
      # Launch a timer to refresh the file list
      Gtk.timeout_add(Config[:files_refresh_interval] * 1000) do 
        do_refresh
        true
      end
    end
    
    private

    # Lunch the refresh of the tree
    def do_refresh
      @file_tree_mutex.synchronize do
        @file_tree.refresh
      end
    end

    # Create the file tree
    def initialize_file_tree(exclude_file_list)
      @file_tree = ListedTree.new(exclude_file_list)

      @file_tree.add_too_many_files_signal do |nbfiles|
        dialog = Gtk::MessageDialog.new(nil,
                                        Gtk::MessageDialog::Flags::MODAL,
                                        Gtk::MessageDialog::Type::QUESTION,
                                        Gtk::MessageDialog::ButtonsType::YES_NO,
                                        "A large number of files will be processed (more than #{nbfiles}). This could take a long time. Continue anyway ?")
        dialog.set_icon_list(Icons.window_icons)
        if dialog.run == Gtk::Dialog::RESPONSE_NO
          puts "\n\nToo many files. The user chose to stop loading. Exiting now.\n\n"
          exit
        end
        dialog.hide
        dialog.destroy
      end

      # Register to receive a signal when a file is added or removed
      @file_tree.add_refresh_signal do |method, file|
        case method
        when :add
          add_to_tree(file)
        when :remove
          remove_file_from_tree(file)
        when :refresh
          refresh_row_for(file)
        end
        @gtk_filtered_tree_model.refilter
      end
    end

    # Add a file to the tree
    def add_to_tree(file)
      parent = file.parent ? file.parent.row : nil
      # If we need a separator and it's a directory, we add it
      if Config[:file_directory_separator] and file.instance_of? ListedDirectory
        new_row = @gtk_tree_store.append(parent)
        new_row[TYPE] = TYPE_SEPARATOR
        new_row[SORT] = "1-#{file.path}-2"
      end
      # Add the row for the file
      new_row = @gtk_tree_store.append(parent)
      new_row[NAME] = file.name
      new_row[PATH] = file.path
      new_row[ICON] = file.icon
      new_row[STATUS] = file.status_text if Config[:files_show_status]
      file.row = new_row # so will find it later fast
      if file.instance_of? ListedDirectory
        new_row[SORT] = "1-#{file.path}-1"
        new_row[TYPE] = TYPE_DIRECTORY
      else
        new_row[SORT] = "2-#{file.path}-1"
        new_row[TYPE] = TYPE_FILE
      end
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
        @gtk_tree_store.remove(iter)
      end
    end

    # Called when the status of the file has changed
    def refresh_row_for(file)
      if iter = file.row
        iter[ICON] = file.icon
        iter[STATUS] = file.status_text if Config[:files_show_status]
      end
    end
  end
end

