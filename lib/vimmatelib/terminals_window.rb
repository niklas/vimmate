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
require 'vte'
require 'vimmatelib/config'

module VimMate

  # Do not load the terminals if they are disabled
  Requirer.raise_load_error_if do
    not Config[:terminals_enabled]
  end

  class ::Vte::Terminal
    attr_accessor :pid
  end

  # The window that contains the terminals
  class TerminalsWindow

    # Create a TerminalsWindow
    def initialize
      @expander_signal = Set.new
      
      # Create the tabbed page
      @gtk_notebook = Gtk::Notebook.new
      @gtk_notebook.scrollable = true
      # Add a terminal at startup
      @gtk_notebook.append_page(new_terminal)
      # The last page is just an icon to create new tabs
      @gtk_notebook.append_page(Gtk::EventBox.new,
                                Gtk::Image.new(Gtk::Stock::NEW, Gtk::IconSize::MENU))
      # When we try to go to the last page, we create a new terminal instead
      @gtk_notebook.signal_connect_after("switch-page") do |notebook, page, page_num|
        add_new_terminal if page_num == (@gtk_notebook.n_pages - 1)
      end
      @gtk_notebook.set_size_request(0, Config[:terminals_height])
    end

    # The "window" for this object
    def gtk_window
      @gtk_notebook
    end

    # Add a block that will be called when the user choose to expand or
    # close the expander. The block takes one argument: if the expander
    # is opened or closed
    def add_expander_signal(&block)
      @expander_signal << block
    end

    # Set the focus to the current terminal
    def focus_terminal
      page = @gtk_notebook.get_nth_page(@gtk_notebook.page)
      page.has_focus = true if page
    end

    # Add a new terminal at the left of the tab bar.
    def add_new_terminal
      page_num = @gtk_notebook.n_pages - 1
      @gtk_notebook.insert_page(page_num, new_terminal)
      @gtk_notebook.page = page_num
    end

    # Deletes terminal with number *page_num*, defaults to current page number.
    def delete_current_terminal
      page = @gtk_notebook.get_nth_page(@gtk_notebook.page)
      prev_terminal
      Process.kill 'HUP', page.pid
    end

    # Switch the next (right) terminal, if there exists one. Otherwise start
    # again with the first terminal on the left.
    def next_terminal
      if @gtk_notebook.page < @gtk_notebook.n_pages - 2
        @gtk_notebook.next_page
      else
        @gtk_notebook.page = 0
      end
    end

    # Switch the previous (left) terminal, if there exists one. Otherwise start
    # with again with the last terminal on the right.
    def prev_terminal
      if @gtk_notebook.page > 0
        @gtk_notebook.prev_page
      else
        @gtk_notebook.page = @gtk_notebook.n_pages - 2
      end
    end
    
    private

    # Create a new terminal and return it
    def new_terminal
      # Setup of the terminal
      gtk_terminal = Vte::Terminal.new
      gtk_terminal.audible_bell = Config[:terminals_audible_bell]
      gtk_terminal.visible_bell = Config[:terminals_visible_bell]
      gtk_terminal.set_font(Config[:terminals_font])
      forecolor = Gdk::Color.parse(Config[:terminals_foreground_color])
      backcolor = Gdk::Color.parse(Config[:terminals_background_color])
      gtk_terminal.set_colors(forecolor, backcolor, [])

      # Hide and destroy the terminal when the shell exits
      gtk_terminal.signal_connect("child-exited") do |terminal|
        break if @gtk_notebook.destroyed?
        # Select the page before
        page_num = @gtk_notebook.page_num(terminal)
        if page_num == 0
          @gtk_notebook.page = 0
        else
          @gtk_notebook.page = page_num - 1
        end
        # Hide it and destroy it after a while
        terminal.hide
        Thread.new do
          sleep(5)
          terminal.destroy unless terminal.destroyed?
        end
      end
      # When the title of the terminal changes, set the name of the page
      gtk_terminal.signal_connect("window-title-changed") do |terminal|
        @gtk_notebook.set_tab_label_text(terminal, terminal.window_title)
      end
      if (Config[:terminals_login_shell])
       begin
         require 'etc'
       rescue LoadError
       end
       shell = (ENV["SHELL"] || Etc.getpwnam(Etc.getlogin).shell rescue nil || "/bin/sh") 
       gtk_terminal.pid = gtk_terminal.fork_command(shell, ["-l"])
      else
        gtk_terminal.pid = gtk_terminal.fork_command
      end
      gtk_terminal.feed_child(Config[:terminals_autoexec])
      gtk_terminal.show
      gtk_terminal
    end

  end
end

