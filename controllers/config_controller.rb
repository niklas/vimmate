class ConfigController < ActiveWindow::Controller

  attr_reader :boxes, :fields

  def setup
    @fields = {}
    @boxes = []
    with_options(:pack => general_config) do |general|
      general.create_field(:files_use_search, :label => 'Use Search')
      general.create_field(:files_use_ellipsis, :label => 'Shorten Filenames')
    end
  end

  def save_settings
    VimMate::Config::DEFAULT_CONFIG.keys.each do |key|
      unless (new_val = val_of(key)).nil?
        VimMate::Config.config[key] = new_val
        puts "saving #{key} => #{new_val}"
      end
    end
    VimMate::Config.write_config
    close_window
  end

  def reset_settings
    boxes.each(&:destroy)
    setup
  end

  def open_window
    config_window.show_all
  end

  def close_window
    config_window.hide
  end

  private

  def create_field(key, options = {})
    val = VimMate::Config[key]

    box = Gtk::HBox.new(true, 10)
      label = Gtk::Label.new options.delete(:label) || key.to_s.humanize
      label.xalign = 1
    box.pack_start label, true, true 
      field = field_for val
      fields[key] = field
    box.pack_start field, true, false

    boxes << box

    container = options.delete(:pack) || general_config
    container.pack_start box, false, false
  end

  def val_of(key)
    return unless field = fields[key]
    case VimMate::Config::DEFAULT_CONFIG[key]
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
      e = Gtk::CheckButton.new
      e.active = val
      e
    else
     Gtk::Label.new(val.to_s)
    end
  end
end
