# require 'libglade2'
# require 'gtk2'

class ActiveWindow::Controller
  include Singleton
    
  attr_accessor :application
  
  def app
    application
  end
  
  def widget(name)
    application.widget(name)
  end
  
  def controller
    application.controller
  end
  
  def window
    application.window
  end
  
  def database
    application.database
  end
  
  # called on startup
  def setup
  end
  
  # called on startup, after setup has been called for all controllers
  def post_setup
  end

  def pref_set(key,value)
    Preference.delete_all ['pref = ?', key]
    Preference.create(:pref => key, :value => value)
    value
  end
  
  def pref_get(key)
    pref = Preference.find_by_pref(key)
    return pref.value if pref
    return nil
  end

  def pref_get_or_set(key,value)
    pref_get(key) || pref_set(key,value)
  end  

  def method_missing(name, *args, &block)
    application.send name, *args, &block
  end
end

