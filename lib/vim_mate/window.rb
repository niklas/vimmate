module VimMate
  # Represents the main window of the application
  class Window < ActiveWindow::Base


    attr_accessor :vim, :file_tree, :terminals_window, :tags_tree

    after_initialize :setup_layout_from_config

    after_initialize :setup_components
    def setup_components
    end

    def open_file_in_vim(row, mode=Config[:files_default_open_in_tabs] ? :tab : :open)
      if row.file? && row.exists?
        vim.open row.full_path, mode
      end
    end

    def on_file_tree_row_activated(row, *args)
      open_file_in_vim row
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

