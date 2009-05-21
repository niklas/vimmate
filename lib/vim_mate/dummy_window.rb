module VimMate

  # Represents a dummy window used when a feature is missing
  class DummyWindow

    attr_reader :gtk_window

    # Create a DummyWindow
    def initialize
      @gtk_window = Gtk::EventBox.new
    end
  end
end

