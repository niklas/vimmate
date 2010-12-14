module VimMate
  class App < ActiveWindow::Application
    def initialize(opts={})
      @excludes = opts.delete(:excludes)
      super
    end
    def file_tree
      files.file_tree
    end
    def files
      controller[:file_filter]
    end
    def vim
      controller[:vim].vim
    end

    widget :file_tree_view
    widget :tree_scroller
    widget :main_pane
    widget :general_config
    widget :files_filter_button
    widget :files_pane
    widget :file_popup
    widget :files_filter_term

    def add_path(path)
      file_tree.initial_adding do
        file_tree.add_path(path)
      end
    end

    def post_setup
      super

      @excludes.each do |rule|
        file_tree.exclude! rule
      end unless @excludes.blank?

      # If there are no files given, open an empty window
      # If files are specified on the command line, use them
      ARGV.each do |file|
        path = File.expand_path(file)
        add_path(path)
        #window.vim.open(path, :tab)
      end
    end

    def run
      GLib::Timeout.add(23) do
        vim.start
        false
      end
      super
    end
  end
end
