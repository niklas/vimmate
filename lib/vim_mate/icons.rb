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

module VimMate

  # Manages the icons that can be loaded from the disk
  class Icons
    include NiceSingleton
    
    # The filenames for the icons of the windows
    WINDOW_ICON_FILENAME = 'vimmate%d.png'.freeze
    # The size for the icons of the windows
    WINDOW_ICON_SIZES = [16, 32, 48].freeze

    Overlays = %w(scm progress type)

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

    def method_missing(meth, *args, &block)
      if meth.to_s =~ /_overlayed_with_/
        overlay_icon(meth, *args)
      elsif meth.to_s =~ /_icon$/
        build_icon(meth)
      else
        raise NoMethodError, "method not found: #{meth}"
      end
    end

    def free_position
      @free_overlays ||= Overlays.dup
      @free_overlays.pop
    end

    def by_name(icon_name)
      send (icon_name =~ /_icon$/) ? icon_name : "#{icon_name}_icon"
    end
    private

    # Auto-define a method with _icon for each icon's name
    def build_icon(meth)
      if meth.to_s =~ /^(.*)_icon$/
        name = $1
        path = File.join(Config.images_path, "#{name}.png")
        if File.exists? path
          begin
            icon = Gdk::Pixbuf.new(path) 
            icon.freeze
            # Once loaded, we only need a reader
            self.class.send(:define_method, meth) do
              icon
            end
            return icon
          rescue StandardError => e
            $stderr.puts e.to_s
            $stderr.puts "Problem loading #{name} icon #{path}"
            raise e
          end
        else
          raise "Icon not found: #{path}"
        end
      end
    end

    def overlay_with(original_name,overlay_name=nil,position='south')
      if overlay_name.nil?
        original_name
      else
        "#{original_name}_#{position}_overlayed_with_#{overlay_name}"
      end
    end

    def overlay_icon(meth)
      if meth.to_s =~ /^(.*)_(#{Overlays.join('|')})_overlayed_with_(.*)$/
        original = $1
        original_icon = by_name original
        where = $2
        overlay = $3
        overlay_icon = by_name overlay
        case where
        when 'progress'
          x = y = 1
        when 'tr'
          x = 7; y = 1
        when 'scm'
          x = 1; y = 7
        when 'br'
          x = y = 7
        end
        overlayed = original_icon.dup
        overlayed.composite!(
          overlay_icon,
          x, y,     # start region to render
          8, 8,     # width / height
          x, y,     # offset
          0.5, 0.5, # scale
          Gdk::Pixbuf::INTERP_BILINEAR,  # interpolation
          255  # alpha
        )
        self.class.send(:define_method, meth) do
          overlayed
        end
        return overlayed
      end
    end

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
