class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :full_path, String, :visible => false
  column :status, String, :visible => false
  column :sort, String, :visible => false

  composite_column 'Files' do |col|
    col.add column(:icon, Gdk::Pixbuf), false
    col.add column(:name, String)
  end

  attr_reader :excludes
  def initialize
    super
    @excludes ||= []
    set_sort_column_id self.class.column_id[:sort]
  end

  def add_path(path, parent=nil)
    file = ListedFile.create(:full_path => path)
    unless excludes?(file.full_path)
      iter = add file, parent # || find_by_full_path(file.basename).iter 
      if file.directory?
        file.children_paths.each do |child|
          add_path child, iter
        end
      end
    end
  rescue ArgumentError => e
    STDERR.puts e.message
  end

  # Path ends with a node name contained in the exclude list
  def excludes?(path)
    excludes.any?  {|f| path[-(f.size+1)..-1] == "/#{f}" }
  end

  def exclude!(new_exclude)
    excludes << new_exclude.chomp.strip
  end

end
