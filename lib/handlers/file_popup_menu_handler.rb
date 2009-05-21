module FilePopupMenuHandler
  def on_open_file_clicked(widget)
    open_file_in_vim(file_tree.selected_row)
  end
  def on_split_open_file_clicked(widget)
    open_file_in_vim(file_tree.selected_row, :split)
  end
  def on_tab_open_file_clicked(widget)
    open_file_in_vim(file_tree.selected_row, :tab)
  end
  def on_new_file_clicked(widget)
  end
  def on_new_directory_clicked(widget)
  end
  def on_rename_item_clicked(widget)
  end
  def on_delete_item_clicked(widget)
  end
  def on_refresh_item_clicked(widget)
  end
end
