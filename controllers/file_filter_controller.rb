class FileFilterController < ActiveWindow::Controller
  attr_reader :file_tree, :filtered_file_tree

  def post_setup
    # TODO use ActiveTreeStore derivate
    @file_tree = FileTreeStore.new
    @filtered_file_tree = FilteredFileTreeStore.new(file_tree)

    filtered_file_tree.apply_to_tree file_tree_view

    tree_scroller.set_size_request(Config[:files_opened_width], -1)
    files_filter_button.active = Config[:files_filter_active]
    files_pane.position = Config[:files_search_separator_position]
  end

  # TODO find another poace to put
  def selection_changed
    STDERR.puts "changed selection"
    if row.file_or_directory?
      selected_path_label.text = File.join(row.full_path)
    else
      selected_path_label.text = ""
    end
  end
  def changed
    if files_filter_button.active?
      filter_string = files_filter_term.text

      if filtered_file_tree.filter_string.blank? && filter_string.length == 1 # begin of filtering
        save_expands if Config[:files_auto_expand_on_filter]
      end

      filtered_file_tree.filter = filter_string

      if Config[:files_auto_expand_on_filter]
        filter_string.blank? ? restore_expands : expand_all
      end
    else
      filtered_file_tree.clear_filter
      restore_expands if Config[:files_auto_expand_on_filter]
    end
  end
  alias_method :toggle, :changed

  private
    def save_expands
      @expands = []
      file_tree_view.map_expanded_rows { |tree_view, path| @expands << path }
      @expands
    end

    def restore_expands
      file_tree_view.collapse_all if Config[:files_auto_expand_on_filter]
      unless @expands.nil? || @expands.empty?
        @expands.each do |path|
          file_tree_view.expand_row(path, false)
        end
      end
    end

    def expand_all
      file_tree_view.expand_all
    end


end
