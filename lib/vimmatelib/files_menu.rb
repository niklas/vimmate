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
require 'fileutils'
require 'set'
require 'vimmatelib/config'
require 'vimmatelib/requirer'

module VimMate

  # The pop-up menu used in the file tree
  class FilesMenu

    # Create a FilesMenu
    def initialize(parent_window)
      @parent_window = parent_window
      @open_signals = Set.new
      @refresh_signals = Set.new

      # The last path is the path of the file that was used when
      # the menu was opened
      @last_path = nil

      # Build the menu items
      @gtk_menu = Gtk::Menu.new
     
      @gtk_menu.append(open = Gtk::ImageMenuItem.new(Gtk::Stock::OPEN))
      open.signal_connect("activate") do
        menu_open
      end

      @gtk_menu.append(split_open = Gtk::MenuItem.new("_Split Open"))
      split_open.signal_connect("activate") do
        menu_split_open
      end

      @gtk_menu.append(tab_open = Gtk::MenuItem.new("_Tab Open"))
      tab_open.signal_connect("activate") do
        menu_tab_open
      end
      
      @gtk_menu.append(Gtk::SeparatorMenuItem.new)
      
      @gtk_menu.append(new = Gtk::ImageMenuItem.new(Gtk::Stock::NEW))
      new.signal_connect("activate") do
        menu_new
      end
      
      @gtk_menu.append(new_folder = Gtk::MenuItem.new("New _Folder"))
      new_folder.signal_connect("activate") do
        menu_new_folder
      end
      
      @gtk_menu.append(Gtk::SeparatorMenuItem.new)
      
      @gtk_menu.append(rename = Gtk::MenuItem.new("R_ename"))
      rename.signal_connect("activate") do
        menu_rename
      end

      @gtk_menu.append(delete = Gtk::ImageMenuItem.new(Gtk::Stock::DELETE))
      delete.signal_connect("activate") do  # FIXME segfaults sometimes
        menu_delete
      end

      @gtk_menu.append(Gtk::SeparatorMenuItem.new)

      
      @gtk_menu.append(refresh = Gtk::ImageMenuItem.new(Gtk::Stock::REFRESH))
      refresh.signal_connect("activate") do
        menu_refresh
      end

      @gtk_menu.show_all
    end

    # Open the menu. Specify a path to show where the menu was opened.
    def open(path)
      @last_path = path
      @gtk_menu.popup(nil, nil, 0, 0)
    end

    # Add a block that will be called when the user choose to open a file
    # The block take two argument: the path to the file to open, and a
    # symbol to indicate the kind: :open, :split_open, :tab_open
    def add_open_signal(&block)
      @open_signals << block
    end

    # Add a block that will be called when the user choose to refresh the
    # file tree. The block doesn't take an argument.
    def add_refresh_signal(&block)
      @refresh_signals << block
    end

    private

    # Signals that a file must be opened
    def menu_open
      @open_signals.each do |signal|
        signal.call(@last_path, :open)
      end
    end

    def menu_split_open
      @open_signals.each do |signal|
        signal.call(@last_path, :split_open)
      end
    end

    def menu_tab_open
      @open_signals.each do |signal|
        signal.call(@last_path, :tab_open)
      end
    end

    # Open a dialog to enter a new file name to create
    def menu_new
      dialog = Gtk::FileChooserDialog.new("New file",
                                          @parent_window.gtk_window,
                                          Gtk::FileChooser::ACTION_SAVE,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.set_icon_list(Icons.window_icons)
      dialog.current_folder = if File.directory? @last_path
                                @last_path
                              else
                                File.dirname(@last_path)
                              end
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        begin
          FileUtils.touch(dialog.filename)
        rescue
          $stderr.puts "Cannot touch #{dialog.filename}"
        end
      end
      dialog.destroy
      menu_refresh
    end

    # Open a dialog to enter a new folder name to create
    def menu_new_folder
      dialog = Gtk::FileChooserDialog.new("New folder",
                                          @parent_window.gtk_window,
                                          Gtk::FileChooser::ACTION_CREATE_FOLDER,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.set_icon_list(Icons.window_icons)
      dialog.current_folder = if File.directory? @last_path
                                @last_path
                              else
                                File.dirname(@last_path)
                              end
      dialog.run
      dialog.destroy
      menu_refresh
    end

    # Open a dialog to enter a new name for a file or directory
    def menu_rename
      dialog = Gtk::FileChooserDialog.new("Rename #{File.basename(@last_path)}",
                                          @parent_window.gtk_window,
                                          Gtk::FileChooser::ACTION_SAVE,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.set_icon_list(Icons.window_icons)
      dialog.current_folder = File.dirname(@last_path)
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        begin
          File.rename(@last_path, dialog.filename)
        rescue SystemCallError
          $stderr.puts "Cannot rename from #{@last_path} to #{dialog.filename}"
        end
      end
      dialog.destroy
      menu_refresh
    end

    # Open a dialog and ask the user if he really wants to delete the target
    # file or directory. Note that for safety, directories can only be removed
    # if they are empty.
    def menu_delete
      name = File.basename(@last_path)
      dialog = Gtk::MessageDialog.new(@parent_window.gtk_window,
                                      Gtk::MessageDialog::Flags::MODAL,
                                      Gtk::MessageDialog::Type::QUESTION,
                                      Gtk::MessageDialog::ButtonsType::YES_NO,
                                      if File.directory? @last_path
                                        "Delete directory #{name} ?"
                                      else
                                        "Delete file #{name} ?"
                                      end)
      dialog.set_icon_list(Icons.window_icons)
      if dialog.run == Gtk::Dialog::RESPONSE_YES
        begin
          if File.directory? @last_path
            FileUtils.rmdir(@last_path)
          else
            FileUtils.rm(@last_path)
          end
        rescue
          $stderr.puts "Cannot remove #{@last_path}"
        end
      end
      dialog.destroy
      menu_refresh
    end

    # Signals that the file tree must be refreshed
    def menu_refresh
      @refresh_signals.each do |signal|
        signal.call
      end
    end

  end
end

