class FileFilterController < ActiveWindow::Controller
  attr_reader :file_tree

  def post_setup
    # TODO re-enable excludes
    # TODO local excludes
    # TODO use ActiveTreeStore derivate
    @file_tree = VimMate::FileTreeController.new(:exclude => [])
    tree_scroller.add(file_tree.view)

    tree_scroller.set_size_request(Config[:files_opened_width], -1)

    files_filter_button.active = Config[:files_filter_active]

    files_pane.position = Config[:files_search_separator_position]

    file_tree.on_selection_changed do |row|
      if row.file_or_directory?
        selected_path_label.text = File.join(row.full_path)
      else
        selected_path_label.text = ""
      end
    end
  end
  def changed
    if files_filter_button.active?
      file_tree.filter = files_filter_term.text
    else
      file_tree.clear_filter
    end
  end
  alias_method :toggle, :changed
end
