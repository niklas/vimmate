require 'tree_controller_definitions'
require 'tree_controller'
require 'listed_directory'
module VimMate
  class FileTreeController < TreeController
    attr_reader :references
    attr_reader :store, :sort_column, :model, :view
    attr_reader :filter_string
    def initialize(opts={})
      super()
      @references = Hash.new(nil)
      @initial_add_in_progress = false
      @exclude = opts.delete(:exclude)
      initialize_store
      # create_message 'nothing found'
      initialize_model
      initialize_view
      initialize_columns
      
      # Callbacks
      Signal.on_file_modified do |path|
        Gtk.queue do
          item_for(path).refresh if has_path?(path)
        end
      end
      Signal.on_file_created do |path|
        self << path
        Gtk.queue do
          item_for(path).refresh if has_path?(path)
        end
      end
      Signal.on_file_deleted do |path|
        Gtk.queue do
          destroy_item(path) if has_path?(path)
        end
      end

    end

    def filter_string=(new_filter_string)
      if new_filter_string.empty?
        clear_filter
      else
        @filter_string = new_filter_string
        apply_filter
      end
    end
    alias :filter :filter_string
    alias :filter= :filter_string=

    def filtered?
      !filter_string.nil? and !filter_string.empty?
    end

    def selected_row
      if iter = view.selection.selected
        item_for iter
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
        unless has_path?(full_file_path)
          create_item_for(full_file_path) 
        end
      end
    end

    def refresh(recurse=true)
      each do |item|
        item.refresh
      end
    end

    def expand_first_row
      view.collapse_all
      view.expand_row(Gtk::TreePath.new("0"), false)
    end

    def item_for(something)
      case something
      when Gtk::TreeRowReference
        item_for store.get_iter(something.path)
      when Gtk::TreeIter
        if !something[ListedItem.referenced_type_column].nil?
          build_item(:iter => something)
        end
      when ListedItem
        something
      when Gtk::TreePath
        item_for store.get_iter(something)
      when String
        if has_path?(something)
          item_for references[something]
        else
          raise ArgumentError, "unknown Path given #{something}"
        end
      else
        raise "Gimme a TreeRowRef, TreeIter, TreePath, ListedItem or String (path), no #{something.class} please"
      end
    end

    def has_path? file_path
      references.has_key? file_path
    end



    private
    # Clear the filter, show all rows in tree and try to re-construct
    # the previous collapse state
    def clear_filter
      @filter_string = ''
      @found_count = -1
      model.refilter
      view.collapse_all if Config[:files_auto_expand_on_filter]
      filter
    end

    # Filter tree view so only directories and separators with matching
    # elements are set visible

    def apply_filter
      @found_count = 0
      store.each do |model,path,iter|
        if iter[ListedItem.referenced_type_column] == 'VimMate::ListedFile'
          if iter[ListedItem.name_column].index filter_string
            @found_count += 1
            item_for(iter).show!
          else
            iter[ListedItem.visible_column] = false
          end
        else
          iter[ListedItem.visible_column] = false
        end
      end
      model.refilter
      view.expand_all if Config[:files_auto_expand_on_filter]
    end

    def each
      store.each do |model,path,iter|
        yield item_for(iter)
      end
    end

    def initialize_view
      @view = Gtk::TreeView.new(model)
      view.selection.mode = Gtk::SELECTION_SINGLE
      view.headers_visible = Config[:file_headers_visible]
      view.hover_selection = Config[:file_hover_selection]
      view.set_row_separator_func do |model, iter|
        iter[ListedItem.referenced_type_column] == 'VimMate::Separator'
      end
    end

    def initialize_columns
      column = ListedFile.setup_view_column(Gtk::TreeViewColumn.new)
      view.append_column(column)
    end

    def initialize_store
      @store = Gtk::TreeStore.new *ListedFile.columns_types
      @sort_column = ListedFile.columns_labels.index(:sort) || 0 || 
        raise(ArgumentError, 'no columns specified')
      store.set_sort_column_id(sort_column)
    end

    def initialize_model
      @model = Gtk::TreeModelFilter.new(store)
      model.set_visible_func do |model, iter|
        if !filtered?
          true
        else
          iter[ListedItem.visible_column]
        end
      end
      @filter_string = ""
      @found_count = -1
    end

    def create_item_for(full_file_path)
      if File.exists? full_file_path
        parent_path = File.dirname full_file_path
        parent = begin
                   item_for(parent_path).iter
                 rescue ArgumentError 
                   nil
                 end
        # TODO add separator
        ## If we need a separator and it's a directory, we add it
        #if Config[:file_directory_separator] and file.instance_of? ListedDirectory
        #  new_row = store.append(parent)
        #  new_row[REFERENCED_TYPE] = TYPE_SEPARATOR
        #  new_row[SORT] = "1-#{file.path}-2"
        #end
        iter = store.append(parent)
        item = build_item :full_path => full_file_path, :iter => iter
        # TODO call hooks here?
        item
      end
    end

    def destroy_item(something)
      if item = item_for(something) and iter = item.iter
        references.delete item.full_path if item.is_a?(ListedFile)
        store.remove iter
        # auto-skips to the next
        # TODO delete separators
        #if iter and iter[REFERENCED_TYPE] == TYPE_SEPARATOR
        #  store.remove(iter)
        #end
      end
    end
    
    def build_item(attrs)
      attrs[:tree] = self
      item = ListedItem.build attrs
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
  end
end
