module InputHandler
  def on_key_pressed(window, event)
    if event.state & Gdk::Window::ModifierType::CONTROL_MASK != 0
      if event.state & Gdk::Window::ModifierType::SHIFT_MASK != 0
        case event.keyval
        # CTRL+SHIFT+S: Set focus to terminal (shell)
        when Gdk::Keyval::GDK_S
          terminals_window.focus_terminal if terminals_window
          next true
        # CTRL+SHIFT+T: New terminal
        when Gdk::Keyval::GDK_T
          terminals_window.add_new_terminal if terminals_window
          next true
        # CTRL+SHIFT+W: Close terminal
        when Gdk::Keyval::GDK_W
          terminals_window.delete_current_terminal if terminals_window
          next true
        # CTRL+SHIFT+L: Set focus to file filter
        when Gdk::Keyval::GDK_L
          files_window.focus_file_filter if files_window
          next true
        # CTRL+SHIFT+F: Set focus to file list
        when Gdk::Keyval::GDK_F
          files_window.focus_file_list if files_window
          next true
        # CTRL+SHIFT+S: Set focus to search file list
        when Gdk::Keyval::GDK_E
          files_window.focus_file_search if files_window
          next true
        # CTRL+SHIFT+V: Set focus to Vim
        when Gdk::Keyval::GDK_V
          vim_window.focus_vim if vim_window
          next true
        else
          next nil
        end
      else
        case event.keyval
        # CTRL+PAGEDOWN: Next terminal
        when Gdk::Keyval::GDK_Page_Down
          terminals_window.next_terminal if terminals_window
          next true
        # CTRL+PAGEDOWN: Previous terminal
        when Gdk::Keyval::GDK_Page_Up
          terminals_window.prev_terminal if terminals_window
          next true
        else
          next nil
        end
      end
    end
    nil
  end

end
