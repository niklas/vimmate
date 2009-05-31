class FileFilterController < ActiveWindow::Controller
  attr_reader :file_tree, :filtered_file_tree

  def post_setup
    # TODO use ActiveTreeStore derivate
    @file_tree = FileTreeStore.new
    @filtered_file_tree = FilteredFileTreeStore.new(file_tree)

    filtered_file_tree.apply_to_tree file_tree_view

    file_tree_view.selection.mode = Gtk::SELECTION_SINGLE
    file_tree_view.headers_visible = VimMate::Config[:file_headers_visible]
    file_tree_view.hover_selection = VimMate::Config[:file_hover_selection]

    tree_scroller.set_size_request(VimMate::Config[:files_opened_width], -1)
    files_filter_button.active = VimMate::Config[:files_filter_active]
    files_pane.position = VimMate::Config[:files_search_separator_position]
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
        save_expands if VimMate::Config[:files_auto_expand_on_filter]
      end

      filtered_file_tree.filter = filter_string

      if VimMate::Config[:files_auto_expand_on_filter]
        filter_string.blank? ? restore_expands : expand_all
      end
    else
      filtered_file_tree.clear_filter
      restore_expands if VimMate::Config[:files_auto_expand_on_filter]
    end
  end
  alias_method :toggle, :changed

  def expand_all
    file_tree_view.expand_all
  end

  def expand_first_row
    file_tree_view.collapse_all
    file_tree_view.expand_row(Gtk::TreePath.new("0"), false)
  end

  def button_pressed(given)
    event = given[:event]
    if event.kind_of? Gdk::EventButton and event.button == 3
      path = file_tree_view.get_path_at_pos(event.x, event.y)
      file_tree_view.selection.select_path(path[0]) if path
      if file_tree_view.selection.selected
        file_popup.popup(nil, nil, 0, 0)
      end
    end
  end

  private
    def save_expands
      @expands = []
      file_tree_view.map_expanded_rows { |tree_view, path| @expands << path }
      @expands
    end

    def restore_expands
      file_tree_view.collapse_all if VimMate::Config[:files_auto_expand_on_filter]
      unless @expands.nil? || @expands.empty?
        @expands.each do |path|
          file_tree_view.expand_row(path, false)
        end
      end
    end

end
