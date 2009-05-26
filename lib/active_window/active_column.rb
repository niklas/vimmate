module ActiveWindow

=begin

ActiveColumn is used to define columns for ActiveTreeStore

=end

  class ActiveColumn 
    attr_accessor :id, :name

    ClassesToSymbols = {
      TrueClass     => :boolean,
      FalseClass    => :boolean,
      String        => :string,
      Time          => :datetime,
      Date          => :datetime,
      Fixnum        => :integer,
      Bignum        => :integer,
      Integer       => :integer,
      Float         => :float,
      Gdk::Pixbuf   => :image
    }

    ##
    ## column: ActiveRecord::ConnectionAdapters::MysqlColumn
    ##
    def self.create(id, name, klass=:string, opts={})
      klass = ClassesToSymbols[klass] if klass.is_a?(Class)
      subclass = case klass # ignore warning this creates
        when :string;         ActiveTextColumn
        when :datetime;       ActiveDateColumn
        when :integer;        ActiveIntegerColumn
        when :float;          ActiveFloatColumn
        when :boolean;        ActiveToggleColumn
        when :image;          ActiveImageColumn
        else; self
      end
      return subclass.new(id, name.to_s, opts)
    end
    
    def initialize(id, name, opts={})
      self.id = id
      self.name = name
      @virtual = true if opts[:virtual] == true
      #puts 'new column: %s %s' % [self.class, name]
    end

    def virtual?
      @virtual
    end
    
    ## return a Gtk::TreeViewColumn appropriate for showing this column
    def view
      raise "There is no way to show #{name} yet."
    end

    ## return the class of the value held for this column in the model
    def data_class
      Object
    end
    
    ## given an active record object, return the attribute
    ## value that corresponds to this column. the returned
    ## value must match the class returned in data_class.
    ## so, you might have to do some conversion.
    def data_value(ar_object)
      ar_object.send(self.name)
    end
  end

  ##
  ## ActiveTextColumn
  ##
  ## For columns with string values
  ##
  class ActiveTextColumn < ActiveColumn
    def data_class
      String
    end    
    def view
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new(self.name, renderer, :text => self.id)
      column.set_sort_column_id(self.id)
      return column
    end
  end

  class ActiveIntegerColumn < ActiveTextColumn
    def data_class
      Integer
    end    
  end
   
  ##
  ## how to do?:
  ##   renderer.signal_connect('toggled') do |cell, path|
  ##     fixed_toggled(treeview.model, path)
  ##   end
  ## 
  class ActiveToggleColumn < ActiveColumn
    def data_class
      TrueClass
    end
    def view
      renderer = Gtk::CellRendererToggle.new
      column = Gtk::TreeViewColumn.new(self.name, renderer, :active => self.id)
      return column
    end
  end
  
  ##
  ## TODO: configure the number of digits printed
  ##
  class ActiveFloatColumn < ActiveColumn
    def data_class
      Float
    end
    def view
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new(self.name, renderer)
      column.set_cell_data_func(renderer) do |col, renderer, model, iter|
        renderer.text = sprintf("%.2f", iter[self.id])
      end
    end
    def data_value(ar_object)
      super(ar_object) || 0
    end
  end

  ##
  ## TODO: configure the date format
  ##
  class ActiveDateColumn < ActiveColumn
    def data_class
      Time
    end
    def view
      renderer = Gtk::CellRendererText.new
      column = Gtk::TreeViewColumn.new(self.name, renderer)
      column.set_cell_data_func(renderer) do |col, renderer, model, iter|
        renderer.text = sprintf("%x %X", iter[self.id])
      end
    end
  end


  class ActiveImageColumn < ActiveColumn
    def data_class
      Gdk::Pixbuf
    end

    def view
      renderer = Gtk::CellRendererPixbuf.new
      column = Gtk::TreeViewColumn.new(self.name, renderer, :pixbuf => self.id)
      return column
    end
  end

  # with pack multiple columns into one, needs
  # * pack instructions (+expand+)
  # * separate render for all Column Subclasses
  class ActiveCompositeColumn < ActiveColumn
    def view
      column = Gtk::TreeViewColumn.new(self.name)
    end
  end

    
end

