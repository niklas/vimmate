class ActiveWindow::Application
  include ActiveSupport::Callbacks
  define_callbacks :after_initialize

  attr_accessor :controller, :database, :glade, :window
  
  def widget(name)
    glade[name]
  end
  
  def initialize(options = {})
    @glade = GladeXML.new(find_glade, nil, options[:title] || 'application' )
    @window = widget(options[:main_window] || 'main_window')
    @window.signal_connect("destroy") { Gtk.main_quit }
    @dot_file_prefs = DotFile.read
    @database = options[:database]
    define_widget_readers
    run_callbacks :after_initialize
  end

  def start
    setup
    post_setup
    window.show
    Gtk.main
  end

  def default_database
    @dot_file_prefs[:db]
  end
  
  def save_default_database(hash)
    @dot_file_prefs[:db] = hash
    @dot_file_prefs.save
  end
  
  # creates the controllers, connects the signals
  # calls 'setup' on each controller
  def setup
    @controller = {}
    
    Module.constants.grep(/.Controller$/).each do |klass|
       ctrl = Kernel.const_get(klass).instance
       ctrl.application = self
       ctrl.setup
       name = klass.to_s.sub('Controller','').underscore.to_sym # eg MyFirstController -> :my_first
       controller[name] = ctrl
    end
    
    glade.signal_autoconnect_full do |source, target, signal, handler, data|
      # for example:
      # source  : instance of Gtk::ImageMenuItem
      # target  : nil
      # signal  : activate, clicked, pressed, etc.
      # handler : window.close, which would call WindowController.close()
      # data    : nil
      #puts [source, target, signal, handler, data].inspect
      source.signal_connect(signal) { |widget,event| self.dispatch(handler, :source => source, :target => target, :signal => signal, :handler => handler, :data => data, :widget => widget, :event => event) }
      #source.signal_connect(signal) { self.(handler, data) }
    end
  end
  
  # calls post_setup on each controller
  def post_setup
    controller.each do |name,ctrl|
      ctrl.post_setup
    end
  end
  
  ##
  ## dispatch a signal to the correct controller
  ##
  def dispatch(handler, event)
    controller_name,action = handler.to_s.split('.')
    unless controller_name and action
      return(error "cannot parse handler '%s'" % handler)
    end

    name = controller_name.to_sym 
    ctrl = controller[name]
    unless ctrl
      puts controller.inspect
      return(error "no controller '%s' defined" % controller_name.camelize)
    end
    
    unless ctrl.respond_to? action
      return(error "controller '%s' does not have a method '%s'" % [ctrl.class, action])
    end
    
    method = ctrl.method(action)
    #puts "calling %s.%s" % [controller_name.camelize, action]
    if method.arity == 0
      method.call
    else
      method.call(event)
    end
  end


  private
  
  def class_exists?(classname)
    return (Kernel::const_get(classname) rescue NameError) != NameError
  end
  
  def error(msg)
    puts msg
  end
  
  def find_glade
    Dir.glob("#{views_directory}/*.glade") do |f|
      return f
    end
    raise "could not find a .glade file in #{views_directory}"
  end

  def views_directory
    File.expand_path File.join(File.dirname($0), '..', 'views')
  end

  def define_widget_readers
    glade.widget_names.each do |widget|
      meth = widget.underscore
      instance_eval <<-EOEVAL
        @#{meth} = glade['#{widget}']
        def #{meth}
          @#{meth}
        end
      EOEVAL
    end
  end
  
end
