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

require 'yaml'
require 'vimmatelib/nice_singleton'

module VimMate

  # Holds the configurations for VimMate. Also read and write this
  # configuration so the user can change it.
  class Config
    include NiceSingleton

    BASE_FILENAME = '.vimmaterc'
    DEFAULT_CONFIG = {
      :window_title => 'VimMate',
      :window_width => 950,
      :window_height => 600,
      :layout_big_terminals => false,
      :files_opened_width => 250,
      :files_closed_width => 25,
      :files_expanded => true,
      :file_headers_visible => false,
      :file_hover_selection => false,
      :file_directory_separator => true,
      :files_filter_active => true,
      :files_auto_expand_on_filter => false,
      :files_refresh_interval => 10,
      :files_default_open_in_tabs => true,
      :files_use_ellipsis => true,
      :files_use_search => true,
      :files_search_ignore_case => true,
      :files_search_separator_position => 400,
      :files_warn_too_many_files => 300,
      :files_warn_too_many_files_each_step => true,
      :files_show_status => true,
      :terminals_enabled => true,
      :terminals_height => 50,
      :terminals_font => "10",
      :terminals_foreground_color => "#000000",
      :terminals_background_color => "#FFFFDD",
      :terminals_audible_bell => false,
      :terminals_visible_bell => false,
      :terminals_autoexec => "",
      :terminals_login_shell => false,
      :subversion_enabled => true,
    }.freeze

    # Create the Config class. Cannot be called directly
    def initialize
      # Set the full path to the configuration file. In the user's
      # HOME or the current directory
      if ENV['HOME']
        self.class.const_set(:FILENAME, File.join(ENV['HOME'], BASE_FILENAME))
      else
        self.class.const_set(:FILENAME, BASE_FILENAME)
      end
      @config = DEFAULT_CONFIG.dup
    end

    # Access the configuration hash
    def config
      read_config
      @config.freeze
      # Once read, we only need a simple reader
      self.class.send(:attr_reader, :config)
      config
    end

    # Easy access to the configuration hash
    def [](symbol)
      config[symbol.to_sym]
    end

    # Get the lib path
    def lib_path
      File.dirname(File.expand_path(__FILE__))
    end
    
    private

    # Read the configuration file
    def read_config
      # Write the default if it doesn't exist
      unless File.exist? FILENAME
        write_config
        return
      end
      # Read the configuration file and merge it with the default
      # so if the user doesn't specify an option, it's set to the default
      @config.merge!(YAML.load_file(FILENAME))
      write_config
    rescue StandardError => e
      $stderr.puts e.to_s
      $stderr.puts "Problem reading config file #{FILENAME}, using default"
    end

    # Write the configuration file
    def write_config
      File.open(FILENAME, 'w') do |file|
        YAML.dump(@config, file)
      end
    rescue StandardError => e
      $stderr.puts e.to_s
      $stderr.puts "Problem writing config file #{FILENAME}"
    end
  end
end

