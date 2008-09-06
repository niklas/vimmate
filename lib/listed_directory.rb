require 'listed_file'
module VimMate
  class ListedDirectory < ListedFile
    def sort_string
      "1-#{full_path}-1"
    end
    def file?
      false # yeah..!
    end
    def refresh
      super
      #remove_not_existing_files
      add_new_files
    end

    
    # Find files to add
    def add_new_files
      $stderr.puts "adding new files to #{self}"
      begin
        Dir.foreach(full_path) do |file|
          # Skip hidden files
          next if file =~ /^\./
          file_path = File.join(full_path, file)
          # Skip files that we already have, happens in tree
          tree << file_path
        end
      rescue Errno::ENOENT
      end
      @traversed = true
    end

  end
end
