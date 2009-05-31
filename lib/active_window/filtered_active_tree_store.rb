module ActiveWindow
  # This creates a TreeModel which supports filtering. Please give a block that "returns" boolean
  #
  #   filtered_model = ActiveTreeStoreFilter.new model do |filter_string, model, path, iter|
  #     !iter[23].index(filter_string).nil?
  #   end
  class FilteredActiveTreeStore < Gtk::TreeModelFilter
    include TreeStoreExtentions

    attr_reader :filter_string, :found_count
    define_callbacks :before_filter_applied, :after_filter_applied
    define_callbacks :before_clear_filter, :after_clear_filter

    def self.inherited(child_class)
      unfiltered_class_name = child_class.name.sub(/^Filtered/,'')
      unfiltered_class = unfiltered_class_name.constantize
      child_class.columns = unfiltered_class.columns
      child_class.column_id = unfiltered_class.column_id
      child_class.setup_column_id_constants
    rescue NameError => e
      if e.message =~ /uninitialized constant #{unfiltered_class}/
        raise "there is no class named #{unfiltered_class} to filter from"
      else
        raise
      end
    end

    def initialize(child_model)
      super(child_model)
      setup_filter
    end

    def filter_string=(new_filter_string)
      @filter_regexp = nil
      if new_filter_string.empty?
        clear_filter
      else
        @filter_string = new_filter_string
        apply_filter
      end
    end

    def clear_filter
      run_callbacks :before_clear_filter
      @filter_string = ''
      @found_count = -1
      refilter
      run_callbacks :after_clear_filter
    end

    # implement this to oyur own needs
    def iter_visible?(iter)
      true
    end

    private

    def setup_filter
      set_visible_func do |model, iter|
        !filtered? || iter[ self.class.column_id[:visible] ]
      end
    end

    # Iterate over child model and set visible column according to #iter_visible?
    def apply_filter
      run_callbacks :before_filter_applied
      @found_count = 0
      visid = self.class.column_id[:visible]
      child_model.each do |model,path,iter|
        unless filtering?
          iter[ visid ] = true
        else
          if iter_visible?(iter) # found match - mark it and all parents as visible
            @found_count += 1
            iter[ visid ] = true
            i = iter
            while i = i.parent
              i[ visid ] = true
            end
          else
            iter[ visid ] = false
          end
        end
      end
      refilter
      run_callbacks :after_filter_applied
    end

    def filtered?
      !filter_string.blank?
    end
    alias_method :filter, :filter_string
    alias_method :filter=, :filter_string=
    alias_method :filtering?, :filtered?

  end
end
