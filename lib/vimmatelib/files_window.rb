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
require 'vimmatelib/file_tree_view'
require 'vimmatelib/plugins'

module VimMate

  # The window that contains the file tree
  class FilesWindow
    # Create a FilesWindow
    def initialize(exclude_file_list = [], vim_window = FalseClass)
      @vim_window = vim_window
      @open_signal = Set.new
      @menu_signal = Set.new
      #@expander_signal = Set.new
      
      # FIXME find a better place for that
      Thread.abort_on_exception = true

      @tree = FileTreeView.new

      # Double-click, Enter, Space: Signal to open the file
      @tree.view.signal_connect("row-activated") do |view, path, column|
        if row = @tree.find_row_by_iter_path(path) and row.file?
          path = row.path
          @open_signal.each do |signal|
            signal.call(path,
                        Config[:files_default_open_in_tabs] ? :tab_open : :open)
          end
        end
      end

      # Left-click: Select and Signal to open the menu
      @tree.view.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          path = @tree.view.get_path_at_pos(event.x, event.y)
          @tree.view.selection.select_path(path[0]) if path

          if selected = @tree.selected_row and selected.file_or_directory?
            @menu_signal.each do |signal|
              signal.call(selected.path)
            end
          end
        end
      end

      # Create a label to show the path of the file
      gtk_label = Gtk::Label.new
      gtk_label.ellipsize = Pango::Layout::EllipsizeMode::START

      # When a selection is changed in the tree view, we change the label
      # to show the path of the file
      @tree.view.selection.signal_connect("changed") do
        gtk_label.text = ""
        if selected = @tree.selected_row and selected.file_or_directory?
          gtk_label.text = File.join(selected.path,selected.name)
        end
      end
      
      # Same thing as Left-click, but with the keyboard
      @tree.view.signal_connect("popup_menu") do
        if selected = @tree.selected_row and selected.file_or_directory?
          @menu_signal.each do |signal|
            signal.call(selected.path)
          end
        end
      end

      # Put the tree view in a scroll window
      @gtk_scrolled_window = Gtk::ScrolledWindow.new
      @gtk_scrolled_window.set_policy(Gtk::POLICY_AUTOMATIC,
                                      Gtk::POLICY_AUTOMATIC)
      @gtk_scrolled_window.add(@tree.view)
      
      # Set the default size for the file list
      @gtk_scrolled_window.set_size_request(Config[:files_opened_width], -1)

      # Create a box to filter the list
      gtk_filter_box = Gtk::HBox.new
      gtk_filter_box.pack_start(gtk_filter_button = Gtk::ToggleButton.new("Filter"), false, false)
      gtk_filter_box.pack_start(@gtk_file_filter_entry = Gtk::Entry.new, true, true)
      changed_lambda = lambda do
        if gtk_filter_button.active?
          @tree.filter = @gtk_file_filter_entry.text
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
      
      @gtk_top_box = Gtk::VBox.new
      @gtk_top_box.pack_start(gtk_filter_box, false, false)
      @gtk_top_box.pack_start(@gtk_scrolled_window, true, true)
      @gtk_top_box.pack_start(gtk_label, false, false)

      # Create the search file list if it's enabled
      if Config[:files_use_search]
        @gtk_paned_box = Gtk::VPaned.new
        @gtk_paned_box.add(@gtk_top_box)
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

      gtk_window.border_width = 3
    end

    # Recursively add a path at the root of the tree
    def add_path(path)
      file_tree_mutex.synchronize do
        @file_tree.add_path(path)
      end
      self
    end

    # The "window" for this object
    def gtk_window
      if Config[:files_use_search]
        @gtk_paned_box
      else
        @gtk_top_box
      end
    end

    # Refresh the file list
    def refresh
      do_refresh
      self
    end

    # Get the filter: files must contain this string
    def filter
      @tree.filter
    end

    # Set the focus to the file filter
    def focus_file_filter
      @gtk_file_filter_entry.has_focus = true if @gtk_file_filter_entry
    end

    # Set the focus to the file list
    def focus_file_list
      @tree.view.has_focus = true if @tree.view
    end

    # Set the focus to the search file list
    def focus_file_search
      @search_window.focus_file_search if @search_window
    end

    # Expand the first row of the file tree
    def expand_first_row
      @tree.view.collapse_all
      @tree.view.expand_row(Gtk::TreePath.new("0"), false)
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
    #def add_expander_signal(&block)
    #  @expander_signal << block
    #end

    # Indicates that the initial file adding is going on. The timer to refresh
    # the list is started after the initial add.
    def initial_add(&block)
      @file_tree.initial_add(&block)
      file_tree_mutex.synchronize do
        @file_tree.refresh(false)
      end
      expand_first_row
      do_refresh

      #TODO add file monitoring with gamin or fam or something like that
      # Launch a timer to refresh the file list
      Gtk.timeout_add(Config[:files_refresh_interval] * 100000) do 
        puts "Auto-refreshing"
        do_refresh
        true
      end
    end
    
    private

    # Launch the refresh of the tree
    def do_refresh(recurse=true)
      Thread.new do
        file_tree_mutex.synchronize do
          @file_tree.refresh(recurse)
          @tree.model.refilter
        end
      end
    end

    # Create the file tree
    def initialize_file_tree(exclude_file_list)
      @file_tree = ListedTree.new(exclude_file_list)
    end

    def file_tree_mutex
      @file_tree_mutex ||= Mutex.new
    end
  end
end

