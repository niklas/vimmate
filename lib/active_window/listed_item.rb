module ActiveWindow
  # The ListItem is created on the fly
  #  * to oo-abstract methods to its TreeIter
  #  * for iteration in TreeController
  #  * as object in ActiveTreeStore
  class ListedItem

    def initialize(opts = {})
      @traversed = false
      self
    end

    def sort
      "item-#{iter}"
    end

    def icon_name
      nil
    end

    def icon
      VimMate::Icons.by_name icon_name
    end

    # New by Gtk::TreeRowReference
    def self.new_by_reference(reference)
      new(:iter => reference.iter)
    end

    # New by Gtk::TreeIter
    def self.new_by_iter(iter)
      new(:iter => iter)
    end

    def message?
      referenced_type == 'VimMate::Message'
    end

    def separator?
      referenced_type == 'VimMate::Separator'
    end

    def file?
      false
    end

    def directory?
      false
    end

    def file_or_directory?
      false
    end

    def show!
      self.visible = true
      # TODO hide seperator
      #if directory? and Config[:file_directory_separator]
      #  if iter.next!
      #    tree.row_for_iter(iter).show!
      #  end
      #end
    end
    def hide!
      self.visible = false
      # TODO hide seperator
      #if directory? and Config[:file_directory_separator]
      #  if iter.next!
      #    tree.row_for_iter(iter).hide!
      #  end
      #end
    end

    def visible?
      visible
    end

    def matches?(str)
      name.index(str)
    end

    def refresh
    end

    def reference
      @reference ||= Gtk::TreeRowReference.new(tree.store, iter.path)
    end

    def reference=(new_ref)
      if new_ref
        @reference = new_ref
        @iter = tree.store.get_iter(new_ref.path)
      end
    end

    def self.build(attrs)
      if full_path = attrs[:full_path]
        if ::File.directory? full_path
          'ListedDirectory'
        elsif ::File.file? full_path
          'ListedFile'
        else
          self
        end
      elsif iter = attrs[:iter] and !iter[REFERENCED_TYPE].nil?
        iter[REFERENCED_TYPE]
      else
        self
      end.constantize.new attrs
    end

    def to_s
      "#{self.class} [#{iter.path}]"
    end

    def self.modify_icon(scope, &block)
      with = "icon_name_with_#{scope}"
      without = "icon_name_without_#{scope}"
      define_method with do
        block.call(self)
      end
      alias_method without, :icon_name
      alias_method :icon_name, with
    end

  end
end
