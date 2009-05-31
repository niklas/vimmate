class FilteredFileTreeStore < ActiveWindow::FilteredActiveTreeStore
  # Fuzzy search by String
  # 'foo'     => matches la/lu/foo, f/lala/o/gaga/o
  # 'foo/bar' => matches la/afoo/gnarz/barz, but not the above
  def iter_visible?(iter)
    case iter[OBJECT]
    when ListedDirectory; false
    when ListedFile
      iter[filter_column] =~ filter_regexp
    else
      false
    end
  end

  def filter_string=(new_filter_string)
    @filter_regexp = nil
    @filter_column = nil
    super
  end


  def filter_regexp
    @filter_regexp ||= Regexp.new(
      filter_string.split('/').map { |t| 
        Regexp.escape(t).split(//).join('.*') 
      }.join('.*/.*')
    )
  end

  def filter_column
    @filter_column ||= filter_string =~ %r~/~ ? FULL_PATH : NAME
  end

end
