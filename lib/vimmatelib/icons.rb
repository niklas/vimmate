=begin
= VimMate: Vim graphical add-on
Copyright (c) 2006 Guillaume Benny

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end

require 'vimmatelib/nice_singleton'

module VimMate

  # Manages the icons that can be loaded from the disk
  class Icons
    include NiceSingleton
    
    # The filenames for the icons of the windows
    WINDOW_ICON_FILENAME = 'vimmate%d.png'.freeze
    # The size for the icons of the windows
    WINDOW_ICON_SIZES = [16, 32, 48].freeze

    # Name of the icons to load. Will create methods named after
    # the icon's name, with _icon: folder_icon for example.
    ICONS_NAME = [:folder, :file].collect do |f|
      ["", :green, :orange, :red].collect do |c|
        if c.to_s.empty?
          f.to_sym
        else
          "#{f}_#{c}".to_sym
        end
      end
    end.flatten.freeze

    # Create the Icons class. Cannot be called directly
    def initialize
      @gtk_window_icons = []
    end
    
    # Get an array of icons for the windows
    def window_icons
      # Load them
      load_window_icons
      @gtk_window_icons.freeze
      # Once loaded, we only need a reader
      self.class.send(:define_method, :window_icons) do
        @gtk_window_icons
      end
      # Return the value
      window_icons
    end

    # Define a method with _icon for each icon's name
    ICONS_NAME.each do |method|
      define_method("#{method}_icon") do
        # Load the file
        icon = nil
        file = File.join(Config.lib_path, "#{method}.png")
        begin
          icon = Gdk::Pixbuf.new(file) if File.exist? file
        rescue StandardError => e
          $stderr.puts e.to_s
          $stderr.puts "Problem loading #{method} icon #{file}"
        end
        icon.freeze
        # Once loaded, we only need a reader
        self.class.send(:define_method, "#{method}_icon") do
          icon
        end
        icon
      end
    end

    private

    # Load the icons for the windows
    def load_window_icons
      WINDOW_ICON_SIZES.each do |size|
        file = File.join(Config.lib_path, WINDOW_ICON_FILENAME % [size])
        begin
          @gtk_window_icons << Gdk::Pixbuf.new(file) if File.exist? file
        rescue StandardError => e
          $stderr.puts e.to_s
          $stderr.puts "Problem loading window icon #{file}"
        end
      end
    end

  end
end
