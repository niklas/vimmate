require 'tree_controller_definitions'
require 'tree_controller'
require 'listed_directory'
module VimMate
  class FileTreeController < TreeController
    attr_reader :references
    attr_reader :store, :sort_column, :model, :view
    attr_reader :filter_string
    def initialize
      super
      @references = Hash.new(nil)
      initialize_store
      # create_message 'nothing found'
      initialize_model
      initialize_view
      initialize_columns
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
      block.call
    end

    def <<(full_file_path)
      unless references.has_key?(full_file_path)
        item = create_item_for(full_file_path) 
        item.fill
      end
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
      each do |item|
        if item.file?
          if item.matches? filter_string
            @found_count += 1
            item.show! # pre-directories get show automatically
          else
            item.hide!
          end
        else
          item.hide!
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
        row = item_for(iter)
        row.separator?
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
        row = item_for(iter)
        if row.message?
          @found_count == 0
        elsif !filtered?
          true
        elsif row.separator?
          row.visible?
        else
          row.visible?
        end
      end
      @filter_string = ""
      @found_count = -1
    end

    def create_item_for(full_file_path)
      if File.exists? full_file_path
        parent = nil # TODO find parent to new file
        # TODO add separator
        ## If we need a separator and it's a directory, we add it
        #if Config[:file_directory_separator] and file.instance_of? ListedDirectory
        #  new_row = store.append(parent)
        #  new_row[REFERENCED_TYPE] = TYPE_SEPARATOR
        #  new_row[SORT] = "1-#{file.path}-2"
        #end
        iter = store.append(parent)
        references[full_file_path] = Gtk::TreeRowReference.new(store, iter.path)
        item = ListedFile.new_by_full_path_and_iter full_file_path, iter
        # TODO call hooks here?
        item
      end
    end

    def destroy_item(something)
      if item = item_for(something) and iter = item.iter
        store.remove iter
        # auto-skips to the next
        # TODO delete separators
        #if iter and iter[REFERENCED_TYPE] == TYPE_SEPARATOR
        #  store.remove(iter)
        #end
        references.delete item.full_path
      end
    end
    
    def item_for(something)
      case something
      when Gtk::TreeRowReference
        ListedItem.new_by_reference something
      when Gtk::TreeIter
        ListedItem.new_by_iter something
      when ListedItem
        something
      when String
        if references.has_key?(something)
          item_for references[something]
        else
          raise "illegal Path given: #{something}"
        end
      else
        raise "Gimme a TreeRowRef, TreeIter, ListedItem or String (path), no #{something.class} please"
      end
    end

    def create_message(message)
      $stderr.puts "Not implemented: create_message '#{message}'"
      #@message_row = store.append(nil)
      #  @message_row[REFERENCED_TYPE] = TYPE_MESSAGE
      #  @message_row[NAME] = "nothing found"
    end
  end
end
