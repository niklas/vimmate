module ActiveWindow
  # This creates a TreeModel which supports filtering. Please give a block that "returns" boolean
  #
  #   filtered_model = ActiveTreeStoreFilter.new model do |filter_string, model, path, iter|
  #     !iter[23].index(filter_string).nil?
  #   end
  class ActiveTreeStoreFilter < Gtk::TreeModelFilter
    include TreeStoreExtentions

    attr_reader :filter_string
    define_callbacks :before_filter_applied, :after_filter_applied
    define_callbacks :before_clear_filter, :after_clear_filter

    def initialize(model, &block)
      raise ArgumentError, "please give a block that takes |filter_string, model, path, iter|" unless block_given?
      @@filter_block = block
      super(model)
    end

    def used_columns
      child_model.used_columns
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

    private

    def apply_filter
      run_callbacks :before_filter_applied
      @found_count = 0
      each do |model,path,iter|
        if filtering?
          @@filter_block.call(@filter_string, model, path, iter)
        else
          iter[ListedItem.visible_column] = true
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
