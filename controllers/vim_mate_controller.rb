class VimMateController < ActiveWindow::Controller

  attr_accessor :terminals_window, :tags_tree

  def post_setup
    window.set_default_size( VimMate::Config[:window_width],
                             VimMate::Config[:window_height])
    window.set_icon_list(VimMate::Icons.window_icons)


    # Double-click, Enter, Space: Signal to open the file
    #file_tree.on_row_activated &method(:on_file_tree_row_activated)

    #file_tree.on_right_click &method(:open_file_popup)
    #file_tree.on_popup_menu &method(:open_file_popup)



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

  def pressed_key(given)
    return unless event = given[:event]
    if event.state & Gdk::Window::ModifierType::CONTROL_MASK != 0
      if event.state & Gdk::Window::ModifierType::SHIFT_MASK != 0
        case event.keyval
        # CTRL+SHIFT+S: Set focus to terminal (shell)
        when Gdk::Keyval::GDK_S
          terminals_window.focus_terminal if terminals_window
        # CTRL+SHIFT+T: New terminal
        when Gdk::Keyval::GDK_T
          terminals_window.add_new_terminal if terminals_window
        # CTRL+SHIFT+W: Close terminal
        when Gdk::Keyval::GDK_W
          terminals_window.delete_current_terminal if terminals_window
        # CTRL+SHIFT+L: Set focus to file filter
        when Gdk::Keyval::GDK_L
          files_filter_term.has_focus = true
        # CTRL+SHIFT+F: Set focus to file list
        when Gdk::Keyval::GDK_F
          file_tree_view.has_focus = true
        # CTRL+SHIFT+S: Set focus to search file list
        when Gdk::Keyval::GDK_E
          files_window.focus_file_search if files_window
        # CTRL+SHIFT+V: Set focus to Vim
        when Gdk::Keyval::GDK_V
          vim.focus!
        end
      else
        #case event.keyval
        ## CTRL+PAGEDOWN: Next terminal
        #when Gdk::Keyval::GDK_Page_Down
        #  terminals_window.next_terminal if terminals_window
        #  next true
        ## CTRL+PAGEDOWN: Previous terminal
        #when Gdk::Keyval::GDK_Page_Up
        #  terminals_window.prev_terminal if terminals_window
        #  next true
        #else
        #  next nil
        #end
      end
    end
    nil
  end

end
