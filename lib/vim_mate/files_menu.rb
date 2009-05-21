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

require 'fileutils'
require 'set'
module VimMate

  # The pop-up menu used in the file tree
  class FilesMenu

    # TODO make inline renaming
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

