module ActiveWindow
  class Base
    Root = File.expand_path(File.join( File.dirname(__FILE__), '..', '..'))
    include ActiveSupport::Callbacks
    define_callbacks :after_initialize, :before_start, :after_show

    Dir.glob( File.join( Root, 'lib', 'handlers', '*_handler.rb') ).each do |path|
      require_dependency(path)
      include path.split(%r(/)).last.sub(/\.rb$/,'').classify.constantize
    end
    attr_reader :glade

    def initialize
      @glade = GladeXML.new(self.class.glade_path) {|handler| method(handler)}
      @glade.widget_names.each do |widget|
        meth = widget.underscore
        instance_eval <<-EOEVAL
          @#{meth} = glade['#{widget}']
          def #{meth}
            @#{meth}
          end
        EOEVAL
      end
      meth = self.class.glade_name
      @root = glade[self.class.glade_root_name]
      run_callbacks :after_initialize
    end

    # Show the window and start the main loop. Also starts the
    def start
      run_callbacks :before_start
      show
      Gtk.main_with_queue
    end

    def show
      root.show_all
      run_callbacks :after_show
    end

    def quit
      Gtk.main_quit
    end


    def self.glade_path
      File.join( Root, 'interfaces', "#{glade_name}.glade")
    end

    attr_reader :root
    alias_method :window, :root

    def self.glade_name
      glade_root_name.underscore
    end

    def self.glade_root_name
      name.sub(/:{0,2}Window$/,'').split(/:/).last
    end

  end
end
