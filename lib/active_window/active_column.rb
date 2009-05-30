module ActiveWindow

=begin

ActiveColumn is used to define columns for ActiveTreeStore

=end

  class ActiveColumn 
    attr_accessor :id, :name
    extend ActiveSupport::Memoizable

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
      @virtual = opts[:virtual] == true ? true : false
      @visible = opts[:visible] == false ? false : true
      #puts 'new column: %s %s' % [self.class, name]
    end

    def virtual?
      @virtual
    end

    def hide!
      @visible = false
    end

    def visible?
      @visible
    end
    
    ## return a Gtk::TreeViewColumn appropriate for showing this column
    def view
      raise "There is no way to show #{name} yet."
    end

    def renderer
      raise "There is no way to render #{name} yet."
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

    def view
      r = renderer
      column.pack_start(r, true)
      column.add_attribute(r, attribute, self.id)
      column
    end

    private
    def column
      @gtk_column ||= Gtk::TreeViewColumn.new(self.name)
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
    def renderer
      Gtk::CellRendererText.new
    end
    def attribute
      :text
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
    def renderer
      Gtk::CellRendererToggle.new
    end
    def attribute
      :active
    end
  end
  
  ##
  ## TODO: configure the number of digits printed
  ##
  class ActiveFloatColumn < ActiveColumn
    def data_class
      Float
    end
    def renderer
      Gtk::CellRendererText.new
    end
    def attribute
      :text
    end
    def view
      super.set_cell_data_func(renderer) do |col, renderer, model, iter|
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
    def renderer
      Gtk::CellRendererText.new
    end
    def attribute
      :text
    end
    def view
      super.set_cell_data_func(renderer) do |col, renderer, model, iter|
        renderer.text = sprintf("%x %X", iter[self.id])
      end
    end
  end


  class ActiveImageColumn < ActiveColumn
    def data_class
      Gdk::Pixbuf
    end

    def renderer
      Gtk::CellRendererPixbuf.new
    end

    def attribute
      :pixbuf
    end
  end

  # pack multiple columns into one
  class ActiveCompositeColumn < ActiveColumn
    def initialize(name, opts={})
      self.name = name
      @virtual = true
      @visible = true
    end
    def view
      column
    end
    def add(child_column, expand=true)
      raise ArgumentError, "give an ActiveColumn, not #{child_column.inspect}" unless child_column.is_a?(ActiveColumn)
      child_column.hide!
      rend = child_column.renderer
      column.pack_start(rend, expand)
      column.add_attribute(rend, child_column.attribute, child_column.id)
    end
  end

    
end

