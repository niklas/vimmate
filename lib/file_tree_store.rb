class FileTreeStore < ActiveWindow::ActiveTreeStore
  column :full_path, String, :visible => false
  column :status, String, :visible => false
  column :sort, String, :visible => false

  composite_column 'Files' do |col|
    col.add column(:icon, Gdk::Pixbuf), false
    col.add column(:name, String)
  end

  index_by :full_path

  attr_reader :excludes
  def initialize
    super
    @excludes ||= []
    set_sort_column_id self.class.column_id[:sort]
    ActiveWindow::Signal.on_file_modified { |path| refresh_path(path) }
    ActiveWindow::Signal.on_file_created  { |path| add_path(path)     }
    ActiveWindow::Signal.on_file_deleted  { |path| remove_path(path)  }
  end

  def add_path(path, parent=nil)
    unless excludes?(File.expand_path(path))
      file = ListedFile.create(:full_path => path)
      iter = add file, parent || find_by_full_path( File.dirname(path) )
      if file.directory?
        file.children_paths.each do |child|
          add_path(child, iter)
        end
      end
    end
  rescue ArgumentError => e
    STDERR.puts e.message
  end

  def refresh_path(path)
    if iter = find_by_full_path(path)
      update_iter_from_object(iter, iter[OBJECT])
      if iter[OBJECT].directory?
        each do |iter|
          if iter[FULL_PATH].start_with?(path)
            refresh_path iter[FULL_PATH]
          end
        end
      end
    end
  end

  def remove_path(file_path)
    if has_full_path?(file_path)
      to_remove = []
      each do |model,path,iter|
        if iter[FULL_PATH].starts_with?(file_path)
          to_remove << reference_for(iter)
        end
      end
      to_remove.each do |element|
        i = get_iter(element.path)
        remove(i) if i
      end
    end
  end

  # Path ends with a node name contained in the exclude list
  def excludes?(path)
    excludes.any?  {|f| path[-(f.size+1)..-1] == "/#{f}" }
  end

  def exclude!(new_exclude)
    excludes << new_exclude.chomp.strip
  end

end
