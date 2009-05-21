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



      
      # Create the search file list if it's enabled
      if Config[:files_use_search]
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
    end

    # Recursively add a path at the root of the tree
    def add_path(path)
      @tree.add_path(path)
      self
    end

    # The "window" for this object
    def gtk_window
      #if Config[:files_use_search]
      #  @gtk_paned_box
      #else
      #  @gtk_top_box
      #end
      glade['MainWindow']
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
      files_filter_term.has_focus = true if files_filter_term
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
      @tree.expand_first_row
    end

    # Add a block that will be called when the user choose to open a file
    # The block takes two arguments: the path to the file to open, and a
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
      @tree.initial_add(&block)
      do_refresh

      ## Launch a timer to refresh the file list
      #Gtk.timeout_add(Config[:files_refresh_interval] * 100000) do 
      #  puts "Auto-refreshing"
      #  do_refresh
      #  true
      #end
    end
    
    private

    # Launch the refresh of the tree
    def do_refresh(recurse=true)
      Thread.new do
        file_tree_mutex.synchronize do
          @tree.refresh
          @tree.model.refilter
          @tree.expand_first_row
        end
      end
    end

    def file_tree_mutex
      @file_tree_mutex ||= Mutex.new
    end
  end
end

