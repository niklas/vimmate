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

module VimMate

  # A window that can be used to search for files
  class SearchWindow
    
    # Column for the file name
    NAME = 0
    # Column for the full path of the file
    PATH = 1

    # Create the SearchWindow
    def initialize(file_tree)
      @open_signal = Set.new
      @menu_signal = Set.new
      @file_tree = file_tree
      @filter = /.*/
      
      # File name, Path
      @gtk_list_model = Gtk::ListStore.new(String, String)
      @gtk_list_model.set_sort_column_id(PATH)
      @gtk_filtered_list_model = Gtk::TreeModelFilter.new(@gtk_list_model)
      @gtk_filtered_list_model.set_visible_func do |model, iter|
        if iter[NAME] =~ @filter
          true
        else
          false
        end
      end

      @gtk_list_view = Gtk::TreeView.new(@gtk_filtered_list_model)
      @gtk_list_view.selection.mode = Gtk::SELECTION_SINGLE
      @gtk_list_view.headers_visible = false
      
      # Double-click, Enter, Space: Signal to open the file
      @gtk_list_view.signal_connect("row-activated") do |view, path, column|
        path = @gtk_filtered_list_model.get_iter(path)[PATH]
        @open_signal.each do |signal|
          signal.call(path,
                      Config[:files_default_open_in_tabs] ? :tab_open : :open)
        end
        @gtk_entry.text = ""
      end

      # Left-click: Select and Signal to open the menu
      @gtk_list_view.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          path = @gtk_list_view.get_path_at_pos(event.x, event.y)
          @gtk_list_view.selection.select_path(path[NAME]) if path

          selected = @gtk_list_view.selection.selected
          if selected
            @menu_signal.each do |signal|
              signal.call(selected[PATH])
            end
          end
        end
      end

      # Same thing as Left-click, but with the keyboard
      @gtk_list_view.signal_connect("popup_menu") do
        selected = @gtk_list_view.selection.selected
        if selected
          @menu_signal.each do |signal|
            signal.call(selected[PATH])
          end
        end
      end

      # Add the columns
      column = Gtk::TreeViewColumn.new
      column.title = "Files"
      
      # File name
      text_cell_renderer = Gtk::CellRendererText.new
      if Config[:files_use_ellipsis]
        text_cell_renderer.ellipsize = Pango::Layout::EllipsizeMode::MIDDLE
      end
      column.pack_start(text_cell_renderer, true)
      column.set_attributes(text_cell_renderer, :text => NAME)
      
      @gtk_list_view.append_column(column)

      # Put the tree view in a scroll window
      @gtk_scrolled_window = Gtk::ScrolledWindow.new
      @gtk_scrolled_window.set_policy(Gtk::POLICY_AUTOMATIC,
                                      Gtk::POLICY_AUTOMATIC)
      @gtk_scrolled_window.add(@gtk_list_view)

      # Create a label to show the path of the file
      gtk_label = Gtk::Label.new
      gtk_label.ellipsize = Pango::Layout::EllipsizeMode::START

      # When a selection is changed in the list view, we change the label
      # to show the path of the file and which characters matches in the
      # file name
      @gtk_list_view.selection.signal_connect("changed") do
        gtk_label.markup = ""
        # Nothing to do if there are no selections or if the entry
        # is empty
        next if (selected_row = @gtk_list_view.selection.selected).nil?
        next if @gtk_entry.text.empty?
        # Build a regexp to add markup information on the file name
        match = []
        Regexp.escape(@gtk_entry.text).gsub(/\\.|./) {|c| match << c}
        match_regexp = Regexp.new(match.join("|"), Config[:files_search_ignore_case])
        file_name_markup = selected_row[NAME].gsub(match_regexp) do |c|
          "<b><i>#{c}</i></b>"
        end
        # Join the path and the file name with the markup
        gtk_label.markup = File.join(File.dirname(selected_row[PATH]), file_name_markup)
      end
      
      # Build a box to contain the entry for the filter
      gtk_filter_box = Gtk::HBox.new
      gtk_filter_box.spacing = 10
      gtk_filter_box.border_width = 10
      gtk_filter_box.add(@gtk_entry = Gtk::Entry.new)

      # When the filter changes, create a new regex to filter the file names
      @gtk_entry.signal_connect("changed") do
        @filter = Regexp.new(".*" + Regexp.escape(@gtk_entry.text).gsub(/\\.|./) {|c| "#{c}.*"},
                             Config[:files_search_ignore_case])
        # Unselect everything, filter and reselect the first row
        @gtk_list_view.selection.unselect_all
        @gtk_filtered_list_model.refilter
        if first_row = @gtk_filtered_list_model.iter_first
          @gtk_list_view.selection.select_iter(first_row)
        end
        # Scroll at the top
        @gtk_scrolled_window.vscrollbar.value = @gtk_scrolled_window.vscrollbar.adjustment.lower
      end
      
      # When we press Enter in the entry, open the first file of the list
      @gtk_entry.signal_connect("activate") do
        next if (first_row = @gtk_filtered_list_model.iter_first).nil?
        @open_signal.each do |signal|
          signal.call(first_row[PATH],
                      Config[:files_default_open_in_tabs] ? :tab_open : :open)
        end
        @gtk_entry.text = ""
      end

      # Add the components in a box
      @gtk_container_box = Gtk::VBox.new
      @gtk_container_box.pack_start(gtk_filter_box, false, false)
      @gtk_container_box.pack_start(@gtk_scrolled_window, true, true)      
      @gtk_container_box.pack_start(gtk_label, false, false)


      # TODO put this into file_tree_controller
      # Process file tree event
      #@file_tree.add_refresh_signal do |method, file|
      #  next if file.instance_of? ListedDirectory 
      #  case method
      #  when :add
      #    # Add the new file
      #    new_row = @gtk_list_model.append
      #    new_row[NAME] = file.name
      #    new_row[PATH] = file.path
      #  when :remove
      #    # A file is removed. Find it and remove it
      #    to_remove = []
      #    @gtk_list_model.each do |model,path,iter|
      #      if iter[PATH] == file.path
      #        to_remove << Gtk::TreeRowReference.new(model, path)
      #        break
      #      end
      #    end
      #    to_remove.each do |element|
      #      @gtk_list_model.remove(@gtk_list_model.get_iter(element.path))
      #    end
      #  end
      #end
    end

    # The "window" for this object
    def gtk_window
      @gtk_container_box
    end

    # Set the focus to the entry field in the file search list
    def focus_file_search
      @gtk_entry.has_focus = true if @gtk_entry
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

  end
end

