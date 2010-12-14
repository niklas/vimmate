module ActiveWindow
  # This creates a TreeModel which supports filtering. Please give a block that "returns" boolean
  #
  #   filtered_model = ActiveTreeStoreFilter.new model do |filter_string, model, path, iter|
  #     !iter[23].index(filter_string).nil?
  #   end
  class FilteredActiveTreeStore < Gtk::TreeModelFilter
    include TreeStoreExtentions

    attr_reader :filter_string, :found_count
    attr_reader :unfiltered_store
    define_callbacks :before_filter_applied, :after_filter_applied
    define_callbacks :before_clear_filter, :after_clear_filter

  # BETTER:
  #
  # class FilteredFileStore < ActiveTreeStore.filter 
  #   returns new anonymous class which inherits from Gtk::TreeModelFilter 
  #  we can inherit from -- like Struct.new
  #  .filter is a class method the ActiveTreeStore got extended with
  # end 
  # the #add stuff down there we could replace with GTK's signals
  #   =>

    def self.inherited(child_class)
      unfiltered_class_name = child_class.name.sub(/^Filtered/,'')
      unfiltered_class = unfiltered_class_name.constantize
      child_class.columns = unfiltered_class.columns
      child_class.column_id = unfiltered_class.column_id
      child_class.setup_column_id_constants
      unfiltered_class.class_eval <<-EOCODE
        def add_with_filter_visibility(file, *args)
          iter = add_without_filter_visibility(file, *args)
          filtered_model.set_visibility_for(iter)
          filtered_model.refilter unless initial_add_in_progress?
          iter
        end
        alias_method_chain :add, :filter_visibility
        attr_accessor :filtered_model
      EOCODE
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
      @filtering = false
      @found_count = -1
      refilter
      run_callbacks :after_clear_filter
    end

    # implement this to oyur own needs
    def iter_visible?(iter)
      true
    end

    # Iterate over child model and set visible column according to #iter_visible?
    def apply_filter
      @filtering = true
      run_callbacks :before_filter_applied
      @found_count = 0
      # we could traverse the tree for ourself with #first_iter and TreeIter#next! and #parent,
      # setting visid to true/false accordingly => less method calls, better control
      child_model.each do |model,path,iter|
        set_visibility_for(iter)
      end
      refilter
      run_callbacks :after_filter_applied
    end

    def filtered?
      @filtering
    end
    alias_method :filter, :filter_string
    alias_method :filter=, :filter_string=
    alias_method :filtering?, :filtered?

    def set_visibility_for(iter)
      visid = visibility_column
      vis = true
      if filtering?
        if iter_visible?(iter) # iter matches - mark it and all parents as visible
          @found_count += 1
          vis = true
          i = iter
          while i = i.parent
            i[ visid ] = true
          end
        else
          vis = false
        end
      end
      iter[ visid ] = vis
      iter
    end

    def visibility_column
      self.class.column_id[:visible]
    end

    private

    def setup_filter
      visid = visibility_column
      set_visible_func do |model, iter|
        !filtering? || iter[ visid ]
      end
      child_model.filtered_model = self
      clear_filter
    end

  end
end
