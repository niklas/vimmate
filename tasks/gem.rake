begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name =        %q{vimmate}
    gemspec.summary =     %q{VimMate is a graphical add-on to Vim with IDE-like features.}
    gemspec.description = %q{
      VimMate is a graphical add-on to Vim with IDE-like features: it does more
      than the plain Vim while still being lightweight. Even with the additional
      features, it stays out of the way for it's main task: editing files with Vim.
      VimMate adds functionality to Vim by embedding Vim GTK GUI (gVim) within
      VimMate.
    }
    gemspec.email =       %q{niklas+vimmate@lanpartei.de}
    gemspec.homepage =    %q{http://github.com/niklas/vimmate/}
    gemspec.authors =     ["Niklas Hofer", "Stefan Bethge"]
    gemspec.executables = %w{vimmate}
    gemspec.require_paths = ["lib"]


    # TODO docs would be nice, indeed
    gemspec.has_rdoc = false

    gemspec.files = %w{
      COPYING
      vimmate.gemspec
      config/environment.rb
      controllers/vim_mate_controller.rb
      controllers/file_popup_menu_controller.rb
      controllers/vim_controller.rb
      controllers/file_filter_controller.rb
      TODO
      spec/spec.opts
      spec/spec_helper.rb
      spec/nice_singleton_spec.rb
      spec/active_window/controller_spec.rb
      spec/active_window/active_column_spec.rb
      spec/active_window/active_tree_store_spec.rb
      spec/lib/listed_directory_spec.rb
      spec/lib/listed_file_spec.rb
      spec/lib/file_tree_store_spec.rb
      README
      .autotest
      Rakefile
      views/vim_mate.glade
      CHANGELOG
      bin/vimmate
      images/svn_readonly.png
      images/processing.png
      images/vimmate16.png
      images/folder_orange.png
      images/svn_modified.png
      images/svn_added.png
      images/svn_deleted.png
      images/file_orange.png
      images/vimmate32.png
      images/file.png
      images/vimmate48.png
      images/file_green.png
      images/svn_locked.png
      images/svn_conflict.png
      images/file_red.png
      images/svn_normal.png
      images/folder.png
      images/folder_green.png
      images/folder_red.png
      lib/try.rb
      lib/vim/source.vim
      lib/vim/netbeans.rb
      lib/vim/integration.rb
      lib/vim/buffers.rb
      lib/listed_directory.rb
      lib/gtk_thread_helper.rb
      lib/file_tree_store.rb
      lib/active_window.rb
      lib/active_window/active_tree_store.rb
      lib/active_window/active_column.rb
      lib/active_window/active_tree_store
      lib/active_window/active_tree_store/columns.rb
      lib/active_window/active_tree_store/extentions.rb
      lib/active_window/active_tree_store/index.rb
      lib/active_window/listed_item.rb
      lib/active_window/dot_file.rb
      lib/active_window/filtered_active_tree_store.rb
      lib/active_window/controller.rb
      lib/active_window/signal.rb
      lib/active_window/application.rb
      lib/config_window.rb
      lib/filtered_file_tree_store.rb
      lib/vim_mate/terminals_window.rb
      lib/vim_mate/version.rb
      lib/vim_mate/plugins.rb
      lib/vim_mate/search_window.rb
      lib/vim_mate/icons.rb
      lib/vim_mate/config.rb
      lib/vim_mate/plugins/subversion/init.rb
      lib/vim_mate/plugins/subversion/lib/subversion.rb
      lib/vim_mate/plugins/subversion/lib/file.rb
      lib/vim_mate/plugins/subversion/lib/menu.rb
      lib/vim_mate/plugins/inotify/init.rb
      lib/vim_mate/plugins/inotify/lib/INotify.rb
      lib/vim_mate/plugins/inotify/lib/directory.rb
      lib/vim_mate/requirer.rb
      lib/vim_mate/dummy_window.rb
      lib/vim_mate/tags_window.rb
      lib/vim_mate/files_menu.rb
      lib/vim_mate/nice_singleton.rb
      lib/vim_mate/vim_widget.rb
      lib/listed_file.rb
    }
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
