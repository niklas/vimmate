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
      @file_tree = VimMate::FileTreeController.new(:exclude => [])
      tree_scroller.add(file_tree.view)

      # Double-click, Enter, Space: Signal to open the file
      file_tree.view.signal_connect("row-activated") do |view, path, column|
        if row = file_tree.selected_row and row.file?
          vim.open(row.full_path, Config[:files_default_open_in_tabs] ? :tab_open : :open)
          Signal.emit_file_opened(row.full_path)
        end
      end
      #file_tree.add_menu_signal do |path|
      #  menu.open(path)
      #end

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

    after_show :start_vim
    def start_vim
      vim.start
    end
  end
end

