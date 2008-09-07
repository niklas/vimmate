module VimMate
  module Plugin
    module SubversionMenu
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          alias_method :initialize_without_svn, :initialize
          alias_method :initialize, :initialize_with_svn
        end
      end
      module InstanceMethods
        def initialize_with_svn(*args)
          initialize_without_svn(*args)
          svn_sub_menu = Gtk::Menu.new

          svn_sub_menu.append(svn_add = Gtk::ImageMenuItem.new(Gtk::Stock::ADD))
          svn_add.signal_connect("activate") do
            menu_svn_add
          end

          svn_sub_menu.append(svn_rename = Gtk::MenuItem.new("R_ename"))
          svn_rename.signal_connect("activate") do
            menu_svn_rename
          end

          svn_sub_menu.append(svn_delete = Gtk::ImageMenuItem.new(Gtk::Stock::DELETE))
          svn_delete.signal_connect("activate") do
            menu_svn_delete
          end

          svn_sub_menu.append(svn_revert = Gtk::ImageMenuItem.new(Gtk::Stock::REVERT_TO_SAVED))
          svn_revert.signal_connect("activate") do
            menu_svn_revert
          end

          @gtk_menu.append(subversion = Gtk::MenuItem.new("S_ubversion"))
          subversion.submenu = svn_sub_menu
          @gtk_menu.show_all
        end
        # Add the selected file to subversion
        def menu_svn_add
          Subversion.add(@last_path)
          menu_refresh
        end

        # Rename the selected file with subversion
        def menu_svn_rename
          dialog = Gtk::FileChooserDialog.new("Rename #{File.basename(@last_path)}",
                                              @parent_window.gtk_window,
                                              Gtk::FileChooser::ACTION_SAVE,
                                              nil,
                                              [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                              [Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_ACCEPT])
          dialog.set_icon_list(Icons.window_icons)
          dialog.current_folder = File.dirname(@last_path)
          if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
            Subversion.move(@last_path, dialog.filename)
          end
          dialog.destroy
          menu_refresh
        end
        
        # Revert the selected file in subversion
        def menu_svn_revert
          dialog = Gtk::MessageDialog.new(@parent_window.gtk_window,
                                          Gtk::MessageDialog::Flags::MODAL,
                                          Gtk::MessageDialog::Type::QUESTION,
                                          Gtk::MessageDialog::ButtonsType::YES_NO,
                                          "Do a Subversion Revert on #{File.basename(@last_path)} ?")
          dialog.set_icon_list(Icons.window_icons)
          if dialog.run == Gtk::Dialog::RESPONSE_YES
            Subversion.revert(@last_path)
          end
          dialog.destroy
          menu_refresh
        end

        # Delete the selected file from subversion
        def menu_svn_delete
          dialog = Gtk::MessageDialog.new(@parent_window.gtk_window,
                                          Gtk::MessageDialog::Flags::MODAL,
                                          Gtk::MessageDialog::Type::QUESTION,
                                          Gtk::MessageDialog::ButtonsType::YES_NO,
                                          "Do a Subversion Delete on #{File.basename(@last_path)} ?")
          dialog.set_icon_list(Icons.window_icons)
          if dialog.run == Gtk::Dialog::RESPONSE_YES
            Subversion.remove(@last_path)
          end
          dialog.destroy
          menu_refresh
        end
      end

    end
  end
end
