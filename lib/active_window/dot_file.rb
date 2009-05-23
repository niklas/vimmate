=begin

A simple class for reading and writing settings information
to a dot file (~/.appname.yml)

=end

module ActiveWindow
  class DotFile < ::Hash
    def self.read(fname=nil)
      fname ||= filename
      unless File.exists? fname
        new.save(fname)
      end
      YAML.load_file( fname )
    end

    def save(fname=nil)
      fname ||= self.class.filename
      File.open( fname, 'w+' ) do |out|
        YAML.dump( self, out )
      end
    end

    def self.filename
      File.join ENV['HOME'], ".#{PROGRAM_NAME}.yml"
    end
  end
end
