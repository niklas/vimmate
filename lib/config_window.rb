module VimMate
  class ConfigWindow
    attr_reader :container
    def initialize(main_window=nil)
      @gtk_main_window = Gtk::Dialog.new("Configuration", main_window, Gtk::Dialog::MODAL,
                                         [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_REJECT ],
                                         [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_ACCEPT ]
                                        )
      gtk_window.set_default_size(400,300)
      gtk_window.signal_connect('response') do |win,resp|
        case resp
        when Gtk::Dialog::RESPONSE_ACCEPT
          save_settings
          win.close
        when Gtk::Dialog::RESPONSE_REJECT
          win.close
        when Gtk::Dialog::RESPONSE_NONE
          puts "closing"
        end
      end
      @container = gtk_window.vbox
      fill_container
      gtk_window.show_all
    end
    # The "window" for this object
    def gtk_window
      @gtk_main_window
    end

    def fill_container
      @fields = {}
      Config::DEFAULT_CONFIG.keys.sort {|a,b| a.to_s <=> b.to_s}.each do |key|
        val = Config[key]
        box = Gtk::HBox.new(true,10)
          label = Gtk::Label.new(key.to_s.humanize)
          label.xalign = 1
          box.pack_start label, true, true 

          field = field_for val
          @fields[key] = field
          box.pack_start field, true, false
        container.pack_start box 
      end
    end

    def save_settings
      Config::DEFAULT_CONFIG.keys.each do |key|
        if new_val = val_of(key)
          Config.config[key] = new_val
        end
      end
      Config.write_config
    end

    def val_of(key)
      field = @fields[key]
      case Config::DEFAULT_CONFIG[key]
      when String
        field.text
      when Fixnum
        field.value.to_i
      when Float
        field.value.to_f
      when FalseClass, TrueClass
        field.active?
      end
    end

    def field_for(val)
      case val
      when String
        # TODO make "textarea" for more than 42 chars
        e = Gtk::Entry.new
        e.editable = true
        e.text = val
        e
      when Fixnum, Float
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
