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
require 'callbacks'

module VimMate

  # A file within the tree
  class ListedFile
    @@all_by_path = Hash.new
    attr_reader :name, :path, :parent
    attr_accessor :reference

    # Create a ListedFile from a path and an optional parent ListedDirectory.
    def initialize(new_path, parent = nil)
      @path = File.expand_path new_path
      @name = File.basename(path)
      # FIXME or find parent by parent path
      @parent = parent
      if @parent && !@parent.is_a?(ListedDirectory)
        raise ArgumentError, "parent is no ListedDirectory" 
      end
      self.class.register self
      @last_status = nil
    end

    # Refresh the file. Doesn't do anything since it's the directory
    # that does the job.
    def refresh(*args)
      self
    end

    # The type of icon to use
    def icon_name
      :file
    end

    # Returns the icon for this file
    def icon
      Icons.by_name icon_name
    end

    # Returns the status text for this file
    def status_text
      ""
    end

    def exists?
      File.exists? path
    end

    def self.register(listed_file)
      @@all_by_path[listed_file.path] = listed_file
      ListedTree.added listed_file
    end
    def self.unregister(listed_file)
      @@all_by_path.delete listed_file
      ListedTree.removed listed_file
    end
    def self.all
      @@all_by_path.values
    end
    def self.all_paths
      @@all_by_path.keys
    end
    def self.find_by_path(path)
      @@all[path]
    end
    def self.modify_icon(scope, &block)
      with = "icon_name_with_#{scope}"
      without = "icon_name_without_#{scope}"
      define_method with do
        block.call(self)
      end
      alias_method without, :icon_name
      alias_method :icon_name, with
    end

  end

  # A directory within the tree. Can contain files and other directories.
  class ListedDirectory < ListedFile
    # Create a ListedDirectory from a path and an optional parent.
    def initialize(path, parent = nil)
      super(path, parent)
      @files = Set.new
      @traversed = false
    end
    
    # The type of icon to use
    def icon_name
      if @traversed
        :folder
      else
        Icons.overlay_with 'folder', 'processing', 'progress' 
      end
    end    

    # Yield each files and directory within this directory
    def each_file(&block)
      @files.each(&block)
      self
    end

    def each_directory(&block)
      @files.select {|f| f.is_a? ListedDirectory }.each(&block)
    end

    def files_count
      @files.length
    end

    # Refresh the files from this directory. If it doesn't exist, the
    # file is removed. If it didn't exist before, the file is added.
    def refresh(recurse=true)
      super
      remove_not_existing_files
      add_new_files
      # refresh subdirs. files must not be refreshed this way
      each_directory do |dir|
        dir.refresh
      end if recurse

      ListedTree.refreshed self
      self
    end

    # Find files to add
    def add_new_files
      begin
        Dir.foreach(path) do |file|
          # Skip hidden files
          next if file =~ /^\./
          file_path = File.join(path, file)

          # Skip files that we already have
          next if self.class.all_paths.include? file_path
          next if ListedTree.should_exclude? file_path

          add_new_file_or_directory file_path
        end
      rescue Errno::ENOENT
      end
      @traversed = true
    end

    def add_new_file_or_directory(file_path)
      @files << if File.directory? file_path
                  ListedDirectory.new(file_path, self)
                else
                  ListedFile.new(file_path, self)
                end
    end

    # Find files that do not exist (anymore) and remove them
    def remove_not_existing_files
      files_to_remove = Set.new
      all_paths = Set.new
      each_file do |file|
        file.refresh
        if file.exists?
          all_paths << file.path
        else
          files_to_remove << file
          # @tree_signal.call(:remove, file)
        end
      end
      @files -= files_to_remove
    end
  end

  # A tree of files and directory. Can signal added and removed files.
  class ListedTree
    include Enumerable
    include Callbacks
    @@exclude_file_list = []

    # Create a ListedTree which contains ListedFile and ListedDirectory
    def initialize(exclude_file_list = [])
      @paths = Set.new
      @refresh_signal = Set.new
      #@signal_method = method(:signal)
      @@exclude_file_list << exclude_file_list
      @too_many_files_signal = Set.new
      @warn_too_many_files = false
      @warn_files_count = 0
    end

    # Yield each files and directory at the root of the tree
    def each_path(&block)
      @paths.each(&block)
      self
    end

    def paths_count
      @paths.length
    end
    
    # Add a path: a file or a directory. If it's a directory, all files
    # within this directory are also added
    def add_path(path)
      return unless File.exist? path
      return if should_exclude? path
      @paths << if File.directory? path
                  ListedDirectory.new(path)
                else
                  ListedFile.new(path)
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
    def refresh(recurse=true)
      each_path do |path|
        path.refresh(recurse)
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

    def self.should_exclude?(filepath)
      @@exclude_file_list.any? do |f| 
        # ends with
        filepath[-(f.size+1)..-1] == "/#{f}"
      end
    end
    def should_exclude?(filepath)
      self.class.should_exclude? filepath
    end


    has_callback :after, :removed
    has_callback :after, :refreshed
    has_callback :after, :added
    def self.filter_after_added(file_or_path)
      if file_or_path.is_a? ListedFile
        file_or_path
      else
        ListedFile.find_by_path file_or_path
      end
    end
    after_added do |file_or_directory|
      #$stderr.puts "Added #{file_or_directory.path}"
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

