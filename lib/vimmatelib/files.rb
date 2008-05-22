=begin
= VimMate: Vim graphical add-on
Copyright (c) 2006 Guillaume Benny

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end

require 'set'
require 'vimmatelib/icons'
require 'vimmatelib/requirer'

module VimMate

  # A file within the tree
  class ListedFile
    attr_reader :name, :path, :parent

    # Create a ListedFile from a path and an optional parent. A block
    # must be passed so it can be called to signal changes.
    def initialize(path, parent = nil, &block)
      @path = path
      @name = File.basename(path)
      @parent = parent
      @tree_signal = block
      @tree_signal.call(:add, self)
      @last_status = nil
    end

    # Refresh the file. Doesn't do anything since it's the directory
    # that does the job.
    def refresh
      self
    end

    # Returns the icon for this file
    def icon
      Icons.file_icon
    end

    # Returns the status text for this file
    def status_text
      ""
    end

    # If subversion can be required, change the definition of some functions
    Requirer.require_if('vimmatelib/subversion') do
      # Refresh the file. If the file status has changed, send a refresh
      # signal
      def refresh
        status = Subversion.status(@path)
        if @last_status != status
          @last_status = status
          @tree_signal.call(:refresh, self)
        end
        self
      end
      
      # Return the icon for this file depending on the file status
      def icon
        status = Subversion.status(@path)
        if @last_status != status
          @last_status = status
        end
        case status
        when Subversion::UNVERSIONED, Subversion::EXTERNAL,
             Subversion::IGNORED, Subversion::UNKNOWN
          Icons.send("#{icon_type}_icon")
        when Subversion::NONE, Subversion::NORMAL
          Icons.send("#{icon_type}_green_icon")
        when Subversion::ADDED, Subversion::DELETED,
             Subversion::REPLACED, Subversion::MODIFIED
          Icons.send("#{icon_type}_orange_icon")
        when Subversion::MISSING, Subversion::MERGED,
             Subversion::CONFLICTED, Subversion::OBSTRUCTED,
             Subversion::INCOMPLETE
          Icons.send("#{icon_type}_red_icon")
        end
      end

      # Return the status text for this file depending on the file status
      def status_text
        Subversion.status_text(@path)
      end
    end

    # The type of icon to use
    def icon_type
      :file
    end
  end

  # A directory within the tree. Can contain files and other directories.
  class ListedDirectory < ListedFile
    include Enumerable
    
    # Create a ListedDirectory from a path and an optional parent. A block
    # must be passed so it can be called to signal changes.
    def initialize(path, exclude_file_list, parent = nil, &block)
      super(path, parent, &block)
      @files = Set.new
      @exclude_file_list = exclude_file_list
      refresh
    end

    # Yield each files and directory within this directory
    def each(&block)
      @files.each(&block)
      self
    end

    # Refresh the files from this directory. If it doesn't exist, the
    # file is removed. If it didn't exist before, the file is added.
    def refresh
      super
      # Find files to remove
      files_to_remove = Set.new
      all_paths = Set.new
      each do |file|
        file.refresh
        if File.exist? file.path
          all_paths << file.path
        else
          files_to_remove << file
          @tree_signal.call(:remove, file)
        end
      end
      @files -= files_to_remove

      # Find files to add
      begin
        Dir.foreach(@path) do |file|
          # Skip hidden files
          next if file =~ /^\./
          path = File.join(@path, file)
          next if @exclude_file_list.any? {|f| path[-(f.size+1)..-1] == "/#{f}" }
          # Skip files that we already have
          next if all_paths.include? path
          # Add the new file
          @files << if File.directory? path
                      ListedDirectory.new(path, @exclude_file_list, self, &@tree_signal)
                    else
                      ListedFile.new(path, self, &@tree_signal)
                    end
        end
      rescue Errno::ENOENT
      end
      self
    end

    # The type of icon to use
    def icon_type
      :folder
    end    
  end

  # A tree of files and directory. Can signal added and removed files.
  class ListedTree
    include Enumerable

    # Create a ListedTree which contains ListedFile and ListedDirectory
    def initialize(exclude_file_list = [])
      @paths = Set.new
      @refresh_signal = Set.new
      @signal_method = method(:signal)
      @exclude_file_list = exclude_file_list
      @too_many_files_signal = Set.new
      @warn_too_many_files = false
      @warn_files_count = 0
    end

    # Yield each files and directory at the root of the tree
    def each(&block)
      @paths.each(&block)
      self
    end
    
    # Add a path: a file or a directory. If it's a directory, all files
    # within this directory are also added
    def add_path(path)
      return unless File.exist? path
      return if @exclude_file_list.any? {|f| path[-(f.size+1)..-1] == "/#{f}" }
      @paths << if File.directory? path
                  ListedDirectory.new(path, @exclude_file_list, &@signal_method)
                else
                  ListedFile.new(path, &@signal_method)
                end
      self
    end

    # Indicates that the initial file adding is going on. Used to warn if
    # there are too many files
    def initial_add
      begin
        @warn_files_count = 0
        @warn_too_many_files = true
        yield
      ensure
        @warn_files_count = 0
        @warn_too_many_files = false
      end
    end

    # Refresh the files from the tree. Inexistent files are removed and
    # new files are added
    def refresh
      each do |path|
        path.refresh
      end
      self
    end

    # Add a block that will be called when a file is added or removed.
    # The block take 2 arguments: method and file:
    #  method: :add, :remove or :refresh
    #  file: the ListedFile or ListedDirectory that is affected
    def add_refresh_signal(&block)
      @refresh_signal << block
    end

    # Add a block that will be called when too many files are added.
    # The block takes 1 argument, the number of files that where added.
    def add_too_many_files_signal(&block)
      @too_many_files_signal << block
    end

    private

    # Signal that a file has been added or removed.
    def signal(method, file)
      if @warn_too_many_files
        @warn_files_count += 1
        warn = if Config[:files_warn_too_many_files_each_step]
                 (@warn_files_count % Config[:files_warn_too_many_files]) == 0
               else
                 @warn_files_count == Config[:files_warn_too_many_files]
               end
        if warn
          @too_many_files_signal.each do |block|
            block.call(@warn_files_count)
          end
        end
      end
      @refresh_signal.each do |block|
        block.call(method, file)
      end
    end
  end
end

