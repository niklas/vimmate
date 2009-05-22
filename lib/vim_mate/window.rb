module VimMate
  # Represents the main window of the application
  class Window < ActiveWindow::Base


    attr_accessor :vim, :file_tree, :terminals_window, :tags_tree

    after_initialize :setup_layout_from_config
    def setup_layout_from_config
      window.title           = Config[:window_title]
      window.set_default_size( Config[:window_width],
                               Config[:window_height])
      window.set_icon_list(Icons.window_icons)

      tree_scroller.set_size_request(Config[:files_opened_width], -1)

      files_filter_button.active = Config[:files_filter_active]

      files_pane.position = Config[:files_search_separator_position]
    end

    after_initialize :setup_components
    def setup_components
      # TODO re-enable excludes
      # TODO local excludes
      @file_tree = VimMate::FileTreeController.new(:exclude => [])
      tree_scroller.add(file_tree.view)

      # Double-click, Enter, Space: Signal to open the file
      file_tree.on_row_activated &method(:on_file_tree_row_activated)

      file_tree.on_right_click &method(:open_file_popup)
      file_tree.on_popup_menu &method(:open_file_popup)

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

    def open_file_in_vim(row, mode=Config[:files_default_open_in_tabs] ? :tab : :open)
      if row.file? && row.exists?
        vim.open row.full_path, mode
      end
    end

    def on_file_tree_row_activated(row, *args)
      open_file_in_vim row
    end

    def open_file_popup(row, *args)
      if row.file_or_directory?
        file_popup.popup(nil, nil, 0, 0)
      end
    end

    # Set the focus to the file filter
    def focus_file_filter
      files_filter_term.has_focus = true
    end

    # Set the focus to the file list
    def focus_file_list
      file_tree.view.has_focus = true
    end

    # Set the focus to the search file list
    def focus_file_search
      @search_window.focus_file_search if @search_window
    end

    after_show :start_vim
    def start_vim
      vim.start
    end
  end
end

