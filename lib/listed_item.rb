module VimMate
  # The ListItem is created on the fly
  #  * to oo-abstract methods to its TreeIter
  #  * for iteration in TreeController
  class ListedItem
    attr_reader :iter
    include VimMate::Tree::Definitions::Column
    column :sort, String
    column :visible, FalseClass
    column :name, String
    column :referenced_type, Fixnum # not TYPE because we want to call #type later
    # Type of row: file
    TYPE_FILE = 0
    # Type of row: directory
    TYPE_DIRECTORY = 1
    # Type of row: separator
    TYPE_SEPARATOR = 2
    # Type of row: message ("nothing found")
    TYPE_MESSAGE = 3

    def initialize(opts = {})
      @iter = opts[:iter]
      if fp = opts[:full_path]
        @file_path = File.dirname fp
        @name = File.basename fp
      end
      self
    end

    # New by Gtk::TreeRowReference
    def self.new_by_reference(reference)
      new(:iter => reference.iter)
    end

    # New by Gtk::TreeIter
    def self.new_by_iter(iter)
      new(:iter => iter)
    end

    # method to iter column mapping
    # TODO move this to Tree::Definitions::Column
    def method_missing(meth, *args, &block)
      if col = columns_labels.index(meth.to_sym)
        iter[col]
      #elsif meth.to_s =~ /^(.*)=$/ 
      #  if id = columns_labels.index($1.to_sym)
      #    iter[id] = args.first
      #  else
      #    raise NoMethodError, "illegal setter: #{meth}"
      #  end
      else
        raise NoMethodError, "'#{meth}' is neither a method nor an iter column"
      end
    end

    def icon
      raise "no icon"
    end

    def fill
      columns_labels.each_with_index do |index, label|
        iter[index] = self.send label
      end
    end

    def message?
      iter[REFERENCED_TYPE] == TYPE_MESSAGE
    end

    def separator?
      iter[REFERENCED_TYPE] == TYPE_SEPARATOR
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

  end
end
