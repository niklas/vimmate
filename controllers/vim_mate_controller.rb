class VimMateController < ActiveWindow::Controller

  attr_accessor :vim, :terminals_window, :tags_tree

  def post_setup
    window.set_default_size( Config[:window_width],
                             Config[:window_height])
    window.set_icon_list(VimMate::Icons.window_icons)


    # Double-click, Enter, Space: Signal to open the file
    #file_tree.on_row_activated &method(:on_file_tree_row_activated)

    #file_tree.on_right_click &method(:open_file_popup)
    #file_tree.on_popup_menu &method(:open_file_popup)


    @vim = VimMate::VimWidget.new
    main_pane.pack2(vim.window, true, false)

    #@tags_tree = VimMate::TagsWindow.new(@vim)
    #tags_scroller.add @tags_tree.gtk_window

    ## Set the signals for the file menu
    #menu.add_open_signal do |path, kind|
    #  vim.open(path, kind)
    #end
    #menu.add_refresh_signal do
    #  files.refresh
    #end
  end

end
