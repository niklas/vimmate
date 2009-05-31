  class FileTreeController < ActiveWindow::FilteredTreeWidget


    private
    def iter_visible_through_filter?(iter)
      if filter_with_slash?
        iter[ListedFile.full_path_column]
      else
        iter[ListedFile.name_column]
      end =~ filter_regexp
    end

    def filter_with_slash?
      @filter_with_slash = filter_string.index('') if @filter_with_slash.nil?
      @filter_with_slash
    end
    after_filter_applied :reset_filter_with_slash
    def reset_filter_with_slash
      @filter_with_slash = nil
    end

    # Fuzzy search by String
    # 'foo'     => matches la/lu/foo, f/lala/o/gaga/o
    # 'foo/bar' => matches la/afoo/gnarz/barz, but not the above
    def filter_regexp
      @filter_regexp ||= Regexp.new(
        filter_string.split('/').map { |t| 
          Regexp.escape(t).split(//).join('.*') 
        }.join('.*/.*')
      )
    end

  end
