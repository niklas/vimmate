class VimController < ActiveWindow::Controller
  attr_accessor :vim

  def setup
    @vim = VimMate::VimWidget.new
    main_pane.pack2(vim.window, true, false)
  end

  def open_selected_file(args={})
    if iter = file_tree_view.selection.selected
      mode = VimMate::Config[:files_default_open_in_tabs] ? :tab : :open
      vim.open iter[ FileTreeStore.full_path_column ], mode
    end
  end
end

