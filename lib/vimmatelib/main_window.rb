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
require 'vimmatelib/config'
require 'vimmatelib/icons'
require 'gtk_thread_helper'

module VimMate

  # Represents the main window of the application
  class MainWindow

    attr_accessor :vim_window, :files_window, :terminals_window

    # Create the MainWindow
    def initialize
      @gtk_main_window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
      gtk_window.signal_connect("delete_event") do
        Gtk.main_quit
      end
      gtk_window.title = Config[:window_title]
      gtk_window.set_default_size(Config[:window_width],
                                  Config[:window_height])
      gtk_window.set_icon_list(Icons.window_icons)
      # Add an event handler for keys events
      gtk_window.signal_connect("key-press-event") do |window, event|
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

    # The "window" for this object
    def gtk_window
      @gtk_main_window
    end

    # Show the window and start the main loop. Also starts the
    # window given in parameters. (Used for VimWindow)
    def start(start_window)
      gtk_window.show_all
      start_window.start
      Gtk.main_with_queue
    end

  end
end

