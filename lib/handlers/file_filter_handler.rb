module FileFilterHandler
  def on_filter_changed(widget)
    if files_filter_button.active?
      file_tree.filter = files_filter_term.text
    else
      file_tree.clear_filter
    end
  end
end
