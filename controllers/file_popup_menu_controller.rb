class FilePopupMenuController < ActiveWindow::Controller

  def setup
    @last_path = File.expand_path '.'
  end

  # Open a dialog to enter a new file name to create
  # TODO use path of selected file
  # TODO make inline renaming (like TextMate)
  def new_file(given)
    dialog = Gtk::FileChooserDialog.new("New file",
                                        window,
                                        Gtk::FileChooser::ACTION_SAVE,
                                        nil,
                                        [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                        [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
    #dialog.set_icon_list(Icons.window_icons)
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
  end
  def new_directory(given)
  end
  def rename_item(given)
  end
  def delete_item(given)
  end
  def refresh_item(given)
  end
end
