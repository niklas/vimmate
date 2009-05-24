class FileFilterController < ActiveWindow::Controller
  attr_reader :file_tree, :filtered_file_tree

  def post_setup
    # TODO re-enable excludes
    # TODO local excludes
    # TODO use ActiveTreeStore derivate
    @file_tree = FileTreeStore.new
    @filtered_file_tree = create_filtered_model file_tree do |filter_string, model, path, iter|
      !iter[FileTreeStore::id[:name]].index(filter_string).nil?
    end

    filtered_file_tree.apply_to_tree file_tree_view
    # TODO expand behavior
    #filtered_file_tree.before_filter_applied :save_expands_if_begin_filtering

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
      filtered_file_tree.filter = files_filter_term.text
    else
      filtered_file_tree.clear_filter
    end
  end
  alias_method :toggle, :changed

  def save_expands_if_begin_filtering
    STDERR.puts "save_expands_if_begin_filtering"
    file_tree_view.save_expands if filtered_file_tree.filter_string.blank? #  and new_filter_string.length == 1
  end
end
