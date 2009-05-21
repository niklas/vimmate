module FileFilterHandler
  def on_filter_changed(widget)
    STDERR.puts "filter changed by: #{widget.inspect}"
    if files_filter_button.active?
      @tree.filter = files_filter_term.text
    else
      @tree.clear_filter
    end
  end
end
