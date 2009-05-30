class FilteredFileTreeStore < ActiveWindow::FilteredActiveTreeStore
  def iter_visible?(iter)
    case iter[ self.class.column_id[:object] ]
    when ListedDirectory; false
    when ListedFile
      !(iter[self.class.column_id[:name]].index(filter_string)).nil?
    else
      false
    end
  end
end
