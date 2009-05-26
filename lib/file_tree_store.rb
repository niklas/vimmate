class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :icon, Gdk::Pixbuf
  column :full_path, String, :virtual => true
  column :name, String
  column :status, String
  virtual_column :sort, String

  #pack_column :icon_and_name do |pack|
  #  page << virtual_column :icon, Gdk::Pixbuf
  #  page << virtual_column :name, String
  #end

  def add_path(path, parent=nil)
    add ListedFile.create(:full_path => path)
  end

end
