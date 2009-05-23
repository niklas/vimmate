class VimMateController < ActiveWindow::Controller

  attr_accessor :vim, :file_tree, :terminals_window, :tags_tree

  def warn
    STDERR.puts "VimMateController#warn called"
  end

  def post_setup
    window.set_default_size( Config[:window_width],
                             Config[:window_height])
    window.set_icon_list(VimMate::Icons.window_icons)

    tree_scroller.set_size_request(Config[:files_opened_width], -1)

    files_filter_button.active = Config[:files_filter_active]

    files_pane.position = Config[:files_search_separator_position]

    # TODO re-enable excludes
    # TODO local excludes
    @file_tree = VimMate::FileTreeController.new(:exclude => [])
    tree_scroller.add(file_tree.view)

    # Double-click, Enter, Space: Signal to open the file
    #file_tree.on_row_activated &method(:on_file_tree_row_activated)

    #file_tree.on_right_click &method(:open_file_popup)
    #file_tree.on_popup_menu &method(:open_file_popup)

    file_tree.on_selection_changed do |row|
      if row.file_or_directory?
        selected_path_label.text = File.join(row.full_path)
      else
        selected_path_label.text = ""
      end
    end

    @vim = VimMate::VimWidget.new
    main_pane.pack2(vim.window, true, false)

    @tags_tree = VimMate::TagsWindow.new(@vim)
    tags_scroller.add @tags_tree.gtk_window

    ## Set the signals for the file menu
    #menu.add_open_signal do |path, kind|
    #  vim.open(path, kind)
    #end
    #menu.add_refresh_signal do
    #  files.refresh
    #end
  end

end
