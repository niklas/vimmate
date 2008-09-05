require 'listed_file'
module VimMate
  class ListedDirectory < ListedFile
    def file?
      false # yeah..!
    end
    def refresh
      super
      remove_not_existing_files
      add_new_files
    end
    
    # Find files to add
    def add_new_files
      begin
        Dir.foreach(full_path) do |file|
          # Skip hidden files
          next if file =~ /^\./
          file_path = File.join(full_path, file)

          # Skip files that we already have
          # FIXME this breaks now
          next if tree.has_path? file_path
          next if tree.excludes? file_path

          tree.create_item_for file_path
        end
      rescue Errno::ENOENT
      end
      @traversed = true
    end

  end
end
