class String
  def humanize
    gsub(/_/, " ").capitalize
  end
end
module VimMate
  class ConfigWindow
    attr_reader :container
    def initialize
      @gtk_main_window = Gtk::Window.new(Gtk::Window::TOPLEVEL)
      gtk_window.title = "Configuration" 
      gtk_window.set_default_size(400,300)
      @container = Gtk::VBox.new
      fill_container
      gtk_window.add container
      gtk_window.show_all
    end
    # The "window" for this object
    def gtk_window
      @gtk_main_window
    end

    def fill_container
      Config::DEFAULT_CONFIG.keys.sort {|a,b| a.to_s <=> b.to_s}.each do |key|
        val = Config[key]
        box = Gtk::HBox.new(true,10)
          label = Gtk::Label.new(key.to_s.humanize)
          label.xalign = 1
          box.pack_start label, true, true 

          field = field_for val
          box.pack_start field, true, false
        container.pack_start box 
      end
    end

    def field_for(val)
      case val
      when String
        e = Gtk::Entry.new
        e.editable = true
        e.text = val
        e
      when Fixnum
        Gtk::SpinButton.new(
          Gtk::Adjustment.new(val,0,10000,1,10,1),
          1,0)
      when FalseClass, TrueClass
        e = Gtk::ToggleButton.new
        e.active = val
        e
      else
       Gtk::Label.new(val.to_s)
      end
    end
  end
end
