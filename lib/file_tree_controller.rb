require 'tree_controller_definitions'
require 'filtered_tree_controller'
require 'listed_directory'
module VimMate
  class FileTreeController < FilteredTreeController
    def initialize(opts={})
      super
      @initial_add_in_progress = false
      @exclude = opts.delete(:exclude)
      
      # Callbacks
      Signal.on_file_modified do |path|
        Gtk.queue do
          create_or_find_item_by_path(path).try(:refresh)
        end
      end
      Signal.on_file_created do |path|
        Gtk.queue do
          add_path(path)
          apply_filter
        end
      end
      Signal.on_file_deleted do |path|
        Gtk.queue do
          if has_path?(path)
            destroy_item(path) 
            references.delete path
          end
        end
      end

    end



    # TODO handle initial adding
    def initial_add(&block)
      @initial_add_in_progress = true
      block.call
      model.refilter
      @initial_add_in_progress = false 
    end

    def initial_add_in_progress?
      @initial_add_in_progress
    end

    def <<(full_file_path)
      unless excludes? full_file_path
        Gtk.queue do
          unless has_path?(full_file_path)
            create_item_for(full_file_path)
          end
        end
      end
    end

    def add_path(full_file_path) # wie <<, aber added die erste ebene gleich mit
      return if excludes?(full_file_path)
      Thread.new do
        create_or_find_item_by_path(full_file_path)
        Gtk.queue do
          traverse(full_file_path)
        end
      end
    end

    # Add children recursivly
    def traverse(root_path)
      if (item = item_for(root_path)) && item.directory?
        item.children_paths.each do |path|
          add_path(path)
        end
      end
    end

    def refresh(path=nil)
      Thread.new do
        each do |item|
          if path.nil? || item.full_path.start_with?(path)
            Gtk.queue do
              item.refresh 
            end
          end
        end
      end
    end

    def expand_first_row
      view.collapse_all
      view.expand_row(Gtk::TreePath.new("0"), false)
    end

    def has_path? file_path
      !file_path.nil? && references.has_key?(file_path) && references[file_path]
    end

    def item_for(something)
      case something
      when String
        if has_path?(something)
          item_for references[something]
        else
          raise "unknown path: #{something}"
        end
      else
        super(something)
      end
    end



    private

    # Filter tree view so only directories and separators with matching
    # elements are set visible
    # FIXME make threadsave
    def apply_filter
      @found_count = 0
      store.each do |model,path,iter|
        if filtering?
          if iter[ListedItem.referenced_type_column] == 'ListedFile'
            if path_visible_through_filter? iter[ListedItem.name_column]
              @found_count += 1
              item_for(iter).show!
            else
              iter[ListedItem.visible_column] = false
            end
          else
            iter[ListedItem.visible_column] = false if iter.path
          end
        else
          iter[ListedItem.visible_column] = true
        end
      end
      model.refilter
      view.expand_all if filtering? and Config[:files_auto_expand_on_filter]
    end

    def create_or_find_item_by_path(full_file_path)
      if has_path?(full_file_path)
        item_for(full_file_path)
      else
        add_file_or_directory(full_file_path)
      end
    end

    # TODO new added files do not get filtered
    # TODO expand the rows on filtering
    def add_file_or_directory(full_file_path)
      return if excludes?(full_file_path)
      if File.exists? full_file_path
        parent_path = File.dirname(full_file_path)
        create_item :full_path => full_file_path, :parent => has_path?(parent_path) ? parent_path : nil
      end
    end

    def build_item(attrs)
      item = super
      references[item.full_path] ||= item.reference if item.file_or_directory?
      item
    end

    def create_message(message)
      $stderr.puts "Not implemented: create_message '#{message}'"
      #@message_row = store.append(nil)
      #  @message_row[REFERENCED_TYPE] = TYPE_MESSAGE
      #  @message_row[NAME] = "nothing found"
    end

    # Path ends with a node name contained in the exclude list
    def excludes?(path)
      @exclude.any?  {|f| path[-(f.size+1)..-1] == "/#{f}" }
    end

    private
    def path_visible_through_filter?(path)
      path =~ Regexp.new(filter_string.split(//).join('.*'))
    end

    def created_item(item)
      if item.iter.path.depth == 2
        view.expand_row(item.iter.parent.path, false)
      end
    end

    def removed_item(item)
      references.delete(item.full_path)
    end

  end
end
