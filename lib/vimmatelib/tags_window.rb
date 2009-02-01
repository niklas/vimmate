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
require 'signals'

module VimMate

  class TagsWindow
    
    #treestore columns
    # Column for the tag name
    NAME = 0
    # Column for the line it is in
    LINE = 1
    PATH = 2

    #path_node_connection columns
    NODE = 0
    METHODS = 1
    CLASSES = 2

    def add_parent_rows(paths)
      #add some parents
      @path_node_connection = Hash.new(false)
      paths.each do |path|
        node = @tags_treestore.append(nil)
        node[0] = path.split('/').last
        node[1] = ''
        node[2] = ''
        methods = @tags_treestore.append(node)
        methods[0] = 'Methods'
        methods[1] = ''
        methods[2] = ''
        classes = @tags_treestore.append(node)
        classes[0] = 'Classes'
        classes[1] = ''
        classes[2] = ''
        @path_node_connection[path] = [node, methods, classes]
      end
    end

    def initialize(vim_window = FalseClass)
      @vim_window = vim_window
      @tags_treestore = Gtk::TreeStore.new(String,String,String)
      
      # Tree View
      @tags_tree_view = Gtk::TreeView.new(@tags_treestore)
      @tags_tree_view.selection.mode = Gtk::SELECTION_SINGLE
      @tags_tree_view.headers_visible = Config[:file_headers_visible]
      @tags_tree_view.hover_selection = Config[:file_hover_selection]    
      
      tags_renderer = Gtk::CellRendererText.new
      col = Gtk::TreeViewColumn.new("Identifier", tags_renderer, :text => NAME)
      @tags_tree_view.append_column(col)
      col = Gtk::TreeViewColumn.new("Line", tags_renderer, :text => LINE)
      @tags_tree_view.append_column(col)

      # Double-click, Enter, Space: Signal to open the file
      @tags_tree_view.signal_connect("row-activated") do |view, path, column|
        iter = @tags_treestore.get_iter(path)
        @vim_window.open_and_jump_to_line iter[PATH], iter[LINE].to_i
      end

      Signal.on_file_opened do |path|
        sleep 0.5
        do_refresh_tags
      end

      #@tags_text_buffer = Gtk::TextBuffer.new()
      #gtk_text_view = Gtk::TextView.new(@tags_text_buffer)
      #gtk_text_view.editable = false
      #gtk_text_view.cursor_visible = false

      @gtk_scrolled_window_tags = Gtk::ScrolledWindow.new
      @gtk_scrolled_window_tags.set_policy(Gtk::POLICY_AUTOMATIC,
                                      Gtk::POLICY_AUTOMATIC)
      @gtk_scrolled_window_tags.add(@tags_tree_view)
      
      # Set the default size for the file list
      @gtk_scrolled_window_tags.set_size_request(Config[:files_opened_width], -1)
     
      Signal.on_file_modified do |path|
        paths = @vim_window.get_all_buffer_paths
        if paths.include?(path)
          do_refresh_tags
        end
      end

      #Signal.on_file_deleted do |path|
      #  #do_refresh_tags
      #end
      
      #Signal.on_file_created do |path|
      #  #do_refresh_tags
      #end
    end
    
    # The "window" for this object
    def gtk_window
      @gtk_scrolled_window_tags
    end

    #TODO:
    #refresh upon switch to this tab:
    #switch-page: self, page, page_num
    #Emitted when the user or a function changes the current page.
    #
    #    * self: the object which received the signal.
    #    * page: the new current Gtk::NotebookPage
    #    * page_num: the index of the page

    def do_refresh_tags(paths=nil)
      if not paths
        paths = @vim_window.get_all_buffer_paths
      end

      @tags_treestore.clear
      add_parent_rows(paths)
        
      paths.each do |path|
        #TODO make me dependent/configurable on file type/suffix
        tags = `ctags --sort=1 -ex #{path}`
        last_class = nil

        whats_a_tag = %r[^(\w+)\s+(\w+\s?\w+)\s+(\d+)\s+(\S+)]
        tags.each_line do |tag|
          if elems = whats_a_tag.match(tag)
            id, type, line, file = elems[1..-1]
            case type
            when 'function'
              new_row = @tags_treestore.append(@path_node_connection[path][METHODS])
              new_row.set_value(NAME, id)
              new_row.set_value(LINE, line)
              new_row.set_value(PATH, file)
            when 'class'
              new_row = @tags_treestore.append(@path_node_connection[path][CLASSES])
              new_row.set_value(NAME, id)
              new_row.set_value(LINE, line)
              new_row.set_value(PATH, file)
              last_class = new_row
            when /^(singleton )?method|member$/
              new_row = @tags_treestore.append(last_class)
              new_row.set_value(NAME, id)
              new_row.set_value(LINE, line)
              new_row.set_value(PATH, file)
            end
          end
        end
      end

      @tags_tree_view.expand_all
    end
  end

end
