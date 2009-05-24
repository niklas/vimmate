class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :full_path, String
  column :icon, Gdk::Pixbuf
  column :status, String

  def add_path(path)
    STDERR.puts "ading #{path}"
  end


end
