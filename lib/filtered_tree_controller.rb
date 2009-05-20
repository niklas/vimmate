require 'tree_controller'
module VimMate
  class FilteredTreeController < TreeController
    attr_reader :filter_string
    def initialize(opts = {})
      super
      @filter_string = ''
      # TODO create_message 'nothing found'
    end

    def filter_string=(new_filter_string)
      @filter_regexp = nil
      if new_filter_string.empty?
        clear_filter
        restore_expands
      else
        save_expands if @filter_string.empty? and new_filter_string.length == 1
        @filter_string = new_filter_string
        apply_filter
      end
    end
    alias :filter :filter_string
    alias :filter= :filter_string=

    private
    # Clear the filter, show all rows in tree and try to re-construct
    # the previous collapse state
    def clear_filter
      @filter_string = ''
      @found_count = -1
      model.refilter
      filter
    end

    # TODO alias: refresh_filter ?
    def apply_filter
    end

    def filtered?
      !filter_string.nil? and !filter_string.empty?
    end
    alias :filtering? :filtered?

    def refresh_model
      model.refilter
    end

  end
end
