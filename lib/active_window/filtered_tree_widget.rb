module ActiveWindow
  class FilteredTreeWidget < TreeWidget
    attr_reader :filter_string
    after_initialize :clear_filter
    define_callbacks :after_filter_applied

    def filter_string=(new_filter_string)
      @filter_regexp = nil
      if new_filter_string.empty?
        clear_filter
      else
        save_expands if @filter_string.empty? and new_filter_string.length == 1
        @filter_string = new_filter_string
        apply_filter
      end
    end
    alias :filter :filter_string
    alias :filter= :filter_string=

    # Clear the filter, show all rows in tree and try to re-construct
    # the previous collapse state
    def clear_filter
      @filter_string = ''
      @found_count = -1
      model.refilter
      restore_expands
    end

    private

    # TODO alias: refresh_filter ?
    def apply_filter
      @found_count = 0
      store.each do |model,path,iter|
        if filtering?
          applying_filter(model,path,iter)
        else
          iter[ListedItem.visible_column] = true
        end
      end
      refresh_model
      run_callbacks :after_filter_applied
    end

    def applying_filter(model,path,iter)
      STDERR.puts "must implement #{self.Class}#applying_filter(model,path,iter)"
    end


    def filtered?
      !filter_string.blank?
    end
    alias :filtering? :filtered?

    def refresh_model
      model.refilter
    end

  end
end
