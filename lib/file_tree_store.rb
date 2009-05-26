class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :icon, Gdk::Pixbuf
  column :full_path, String, :virtual => true
  column :name, String
  column :status, String

  def add_path(path, parent=nil)
    add ListedFile.create(:full_path => path)
  end

end
