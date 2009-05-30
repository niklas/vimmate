module ActiveWindow
  class TreeWidget
    include ActiveSupport::Callbacks
    define_callbacks :after_initialize, :before_start
    attr_reader :references
    attr_reader :store, :sort_column, :model, :view
    def initialize(opts = {})
      @references = Hash.new(nil)
      initialize_store
      initialize_model
      initialize_view
      initialize_columns
      run_callbacks :after_initialize
    end
    def selected_row
      if iter = view.selection.selected
        item_for iter
      end
    end

    def on_row_activated(&block)
      view.signal_connect("row-activated") do |view, path, column|
        if row = selected_row
          block.call row, view, path, column
        end
      end
    end

    def on_right_click
      view.signal_connect("button_press_event") do |widget, event|
        if event.kind_of? Gdk::EventButton and event.button == 3
          path = view.get_path_at_pos(event.x, event.y)
          view.selection.select_path(path[0]) if path
          if selected = selected_row
            yield selected, widget, event
          end
        end
      end
    end

    def on_popup_menu
      view.signal_connect("popup_menu") do
        if selected = selected_row
          yield selected
        end
      end
    end

    def on_selection_changed
      view.selection.signal_connect("changed") do
        if selected = selected_row
          yield selected
        end
      end
    end
  end
end
