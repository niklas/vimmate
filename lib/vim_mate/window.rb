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
      tree_scroller.add(@file_tree.view)

      @vim = VimMate::VimWidget.new
      main_pane.pack2(vim.window, true, false)

      @tags_tree = VimMate::TagsWindow.new(@vim)
      tags_scroller.add @tags_tree.gtk_window
    end

    after_show :start_vim
    def start_vim
      vim.start
    end
  end
end

