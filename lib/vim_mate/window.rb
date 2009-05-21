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

module VimMate
  # Represents the main window of the application
  class Window < ActiveWindow::Base


    attr_accessor :vim, :file_tree, :terminals_window, :tags_tree

    def gtk_main_quit
      Gtk.main_quit
    end

    after_initialize :setup_layout_from_config

    def setup_layout_from_config
      window.title = Config[:window_title]
      window.set_default_size(Config[:window_width],
                                  Config[:window_height])
      window.set_icon_list(Icons.window_icons)
      # Add an event handler for keys events

      tree_scroller.set_size_request(Config[:files_opened_width], -1)

      files_filter_button.active = Config[:files_filter_active]

      files_pane.position = Config[:files_search_separator_position]
    end

    after_initialize :setup_components

    def setup_components
      @file_tree = VimMate::FileTreeController.new(:exclude => [])
      tree_scroller.add(@file_tree.view)

      @vim = VimMate::VimWindow.new
      main_pane.pack2(@vim.gtk_window, true, false) if vim

      @tags_tree = VimMate::TagsWindow.new(vim)
      tags_scroller.add @tags_tree.gtk_window
    end

    # The "window" for this object
    def gtk_window
      root
    end


    # files_filter_term.signal_connect("changed", &changed_lambda)
    # files_filter_button.signal_connect("toggled", &changed_lambda)


    def on_key_pressed(window, event)
      if event.state & Gdk::Window::ModifierType::CONTROL_MASK != 0
        if event.state & Gdk::Window::ModifierType::SHIFT_MASK != 0
          case event.keyval
          # CTRL+SHIFT+S: Set focus to terminal (shell)
          when Gdk::Keyval::GDK_S
            terminals_window.focus_terminal if terminals_window
            next true
          # CTRL+SHIFT+T: New terminal
          when Gdk::Keyval::GDK_T
            terminals_window.add_new_terminal if terminals_window
            next true
          # CTRL+SHIFT+W: Close terminal
          when Gdk::Keyval::GDK_W
            terminals_window.delete_current_terminal if terminals_window
            next true
          # CTRL+SHIFT+L: Set focus to file filter
          when Gdk::Keyval::GDK_L
            files_window.focus_file_filter if files_window
            next true
          # CTRL+SHIFT+F: Set focus to file list
          when Gdk::Keyval::GDK_F
            files_window.focus_file_list if files_window
            next true
          # CTRL+SHIFT+S: Set focus to search file list
          when Gdk::Keyval::GDK_E
            files_window.focus_file_search if files_window
            next true
          # CTRL+SHIFT+V: Set focus to Vim
          when Gdk::Keyval::GDK_V
            vim_window.focus_vim if vim_window
            next true
          else
            next nil
          end
        else
          case event.keyval
          # CTRL+PAGEDOWN: Next terminal
          when Gdk::Keyval::GDK_Page_Down
            terminals_window.next_terminal if terminals_window
            next true
          # CTRL+PAGEDOWN: Previous terminal
          when Gdk::Keyval::GDK_Page_Up
            terminals_window.prev_terminal if terminals_window
            next true
          else
            next nil
          end
        end
      end
      nil
    end

  end
end

