class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :icon, Gdk::Pixbuf
  column :full_path, String, :virtual => true
  column :name, String
  column :status, String

  def add_path(path, parent=nil)
    add :full_path => File.expand_path(path), :name => File.basename(path), :status => 'normal'
  end

end
