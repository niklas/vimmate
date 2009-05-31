class VimController < ActiveWindow::Controller
  attr_accessor :vim

  def setup
    @vim = VimMate::VimWidget.new
    main_pane.pack2(vim.window, true, false)
  end

  def open_selected_file
    open_selected_file_as
  end

  def open_selected_file_split
    open_selected_file_as :split
  end

  def open_selected_file_tab
    open_selected_file_as :tab
  end

  private
  def open_selected_file_as(mode = VimMate::Config[:files_default_open_in_tabs] ? :tab : :open)
    if iter = file_tree_view.selection.selected
      vim.open iter[ FileTreeStore.full_path_column ], mode
    end
  end
end

