module VimMate
  # The ListItem is created on the fly
  #  * to oo-abstract methods to its TreeIter
  #  * for iteration in TreeController
  class ListedItem
    attr_reader :iter
    attr_reader :tree
    include VimMate::Tree::Definitions::Column
    column :sort, String
    column :visible, FalseClass
    column :name, String
    column :referenced_type, String # not TYPE because we want to call #type later

    def initialize(opts = {})
      @traversed = false
      @iter = opts[:iter]
      @tree = opts[:tree]
      self.reference = opts[:reference]
      self.sort ||= opts[:sort] || sort_string
      self.visible = true unless visible == false
      self.name ||= opts[:name] || "item-#{iter}"
      self.referenced_type ||= self.class.name.split('::').last
      self
    end

    def sort_string
      "item-#{iter}"
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
      after_show! if responds_to? :after_show!
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
          ListedDirectory
        elsif ::File.file? full_path
          ListedFile
        else
          self
        end
      elsif iter = attrs[:iter]
        VimMate.const_get(iter[REFERENCED_TYPE])
      else
        self
      end.new attrs
    end

    def to_s
      "#{self.class} [#{iter.path}]"
    end

  end
end
