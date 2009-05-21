  class ListedDirectory < ListedFile
    def sort_string
      "1-#{name}-1"
    end
    def icon_name
      'folder'
    end
    def file?
      false # yeah..!
    end
    def directory?
      true
    end
    def exists?
      full_path && ::File.directory?(full_path)
    end
    def refresh
      super
      #remove_not_existing_files
      add_new_files
    end

    def children_paths
      children_names.map {|n| File.join(full_path, n)}
    end

    def children_names
      Dir.entries(full_path).select {|p| p !~ /^\./ }
    end

    
    # Find files to add
    def add_new_files
      begin
        children_paths.each do |file_path|
          tree << file_path
        end
      rescue Errno::ENOENT
      end
      @traversed = true
    end

  end
