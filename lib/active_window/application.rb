class ActiveWindow::Application
  include ActiveSupport::Callbacks
  define_callbacks :after_initialize

  attr_accessor :controller, :database, :window
  attr_reader :builder

  def self.widget(*widgets)
    widgets.each do |widget|
      name = widget.to_s.camelize
      define_method widget do
        builder[name]
      end
    end
  end
  
  def widget(name)
    builder[name]
  end
  
  def initialize(options = {})
    @builder = Gtk::Builder.new
    @builder.add_from_file(find_view)
    @window = widget(options[:main_window] || 'main_window')
    @window.signal_connect("destroy") { Gtk.main_quit }
    @dot_file_prefs = ActiveWindow::DotFile.read
    @database = options[:database]
    run_callbacks :after_initialize
  end

  def start
    setup
    window.show
    run
  end

  def run
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

    builder.connect_signals do |handler_name|
      dispatch(handler_name)
    end

    post_setup
  end
  
  # calls post_setup on each controller
  def post_setup
    controller.each do |name,ctrl|
      ctrl.post_setup
    end
  end
  
  ## gets a handler like "config.reset_settings"
  ## returns the method (reset_settings) of the controller (ConfigController) to use as a callback
  ##
  def dispatch(handler)
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
  end


  private
  
  def class_exists?(classname)
    return (Kernel::const_get(classname) rescue NameError) != NameError
  end
  
  def error(msg)
    puts msg
  end
  
  # TODO find the *.ui file according to app name or whatever
  def find_view
    Dir.glob("#{views_directory}/*.ui") do |f|
      return f
    end
    raise "could not find a .ui file in #{views_directory}"
  end

  def views_directory
    File.join(APP_ROOT, 'views')
  end

end
