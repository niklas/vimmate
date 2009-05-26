  class ListedFile < ActiveWindow::ListedItem
    attr_accessor :full_path, :name, :status

    def self.create(opts = {})
      if fp = opts[:full_path]
        if File.directory?(fp)
          ListedDirectory.new opts
        elsif File.file?(fp)
          ListedFile.new opts
        else
          raise ArgumentError, "does not exist: #{fp}"
        end
      else
        raise ArgumentError, "please give a :full_path, not only #{opts.inspect}"
      end
    end

    def initialize(opts = {})
      super
      if fp = opts[:full_path]
        self.full_path = fp
        self.status = "normal" if VimMate::Config[:files_show_status]
      end
    end
    def icon_name
      'file'
    end
    def refresh
      Gtk.queue do
        self.icon = VimMate::Icons.by_name icon_name
        self.status = "normal" if VimMate::Config[:files_show_status]
      end
    end

    # sets #name AND #fullpath
    def full_path=(new_full_path)
      unless new_full_path.empty?
        @full_path = File.expand_path new_full_path
        self.name  = File.basename new_full_path
      end
    end
    def sort_string
      "2-#{name}-1"
    end
    def file?
      true
    end
    def directory?
      false
    end
    def exists?
      full_path && ::File.file?(full_path)
    end
    def file_or_directory?
      file? || directory?
    end

    def show!
      i = iter
      while i = i.parent
        i[VISIBLE] = true
      end
      super
    end

  end

