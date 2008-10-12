module VimMate
  class TreeController
    def save_expands
      @expands = []
      view.map_expanded_rows { |tree_view, path| @expands << path }
      @expands
    end

    def restore_expands
      view.collapse_all if Config[:files_auto_expand_on_filter]
      unless @expands.nil? || @expands.empty?
        @expands.each do |path|
          view.expand_row(path, false)
        end
      end
    end
  end
end
