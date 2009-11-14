# Version 0.3.0 (2005-09-27) by James Le Cuirot <chewi@ffaura.com>
#	masks updated
#	syscalls instead of /dev/inotify for linux-2.6.13 (are the archs correct?)
#	start/stop methods added for threading
#	ignore_dir_recursively method added
#	Events class removed : not necessary
#	(wd <=> dir) hashed both ways : needed for ignore
#	default watch mask is IN_ALL_EVENTS
#	UnsupportedPlatformError class added to deal with unsupported CPUs and OSes
#
# Version 0.2.3 (2005-01-18) by oxman
#	function ignore_dir : was added
#
# Version 0.2.2 (2005-01-18) by oxman
#	cleaning code (big thanks to gnome at #ruby-lang)
#	rename next_event in each_event (thanks kig)
#
# Version 0.2.1 (2005-01-18) by oxman
#	class Events : use real mask
#
# Version 0.2.0 (2005-01-18) by oxman
#	function watch_dir : only watch
#	function next_event : was added
#	function watch_dir_recursively : was added
#
# Version 0.1.1 (2005-01-17) by oxman
# Correct IN_ var for inotify 0.18

module INotify
	require 'rbconfig'
	
	class UnsupportedPlatformError < RuntimeError
	end
	
	case Config::CONFIG["arch"]
	
		when /i[3-6]86-linux/
			INOTIFY_INIT = 291
			INOTIFY_ADD_WATCH = 292
			INOTIFY_RM_WATCH = 293
		
		when /x86_64-linux/
			INOTIFY_INIT = 253
			INOTIFY_ADD_WATCH = 254
			INOTIFY_RM_WATCH = 255
		
		when /powerpc(64)?-linux/
			INOTIFY_INIT = 275
			INOTIFY_ADD_WATCH = 276
			INOTIFY_RM_WATCH = 277
		
		when /ia64-linux/
			INOTIFY_INIT = 1277
			INOTIFY_ADD_WATCH = 1278
			INOTIFY_RM_WATCH = 1279
		
		when /s390-linux/
			INOTIFY_INIT = 284
			INOTIFY_ADD_WATCH = 285
			INOTIFY_RM_WATCH = 286
		
		when /alpha-linux/
			INOTIFY_INIT = 444
			INOTIFY_ADD_WATCH = 445
			INOTIFY_RM_WATCH = 446
		
		when /sparc(64)?-linux/
			INOTIFY_INIT = 151
			INOTIFY_ADD_WATCH = 152
			INOTIFY_RM_WATCH = 156
		
		when /arm-linux/
			INOTIFY_INIT = 316
			INOTIFY_ADD_WATCH = 317
			INOTIFY_RM_WATCH = 318

		when /sh-linux/
			INOTIFY_INIT = 290
			INOTIFY_ADD_WATCH = 291
			INOTIFY_RM_WATCH = 292

		else raise UnsupportedPlatformError, Config::CONFIG["arch"]
			
	end

	Mask = Struct::new(:value, :name)

	Masks = {
		:IN_ACCESS			=> Mask::new(0x00000001, 'access'),
		:IN_MODIFY			=> Mask::new(0x00000002, 'modify'),
		:IN_ATTRIB			=> Mask::new(0x00000004, 'attrib'),
		:IN_CLOSE_WRITE		=> Mask::new(0x00000008, 'close_write'),
		:IN_CLOSE_NOWRITE	=> Mask::new(0x00000010, 'close_nowrite'),
		:IN_OPEN			=> Mask::new(0x00000020, 'open'),
		:IN_MOVED_FROM		=> Mask::new(0x00000040, 'moved_from'),
		:IN_MOVED_TO		=> Mask::new(0x00000080, 'moved_to'),
		:IN_CREATE			=> Mask::new(0x00000100, 'create'),
		:IN_DELETE			=> Mask::new(0x00000200, 'delete'),
		:IN_DELETE_SELF		=> Mask::new(0x00000400, 'delete_self'),
		:IN_UNMOUNT			=> Mask::new(0x00002000, 'unmount'),
		:IN_Q_OVERFLOW		=> Mask::new(0x00004000, 'q_overflow'),
		:IN_IGNORED			=> Mask::new(0x00008000, 'ignored'),
	}

	Masks.each {|key, value|
		const_set(key, value)
	}
	
	OrMasks = {
		:IN_CLOSE		=> Mask::new(IN_CLOSE_WRITE.value | IN_CLOSE_NOWRITE.value, 'close'),
		:IN_MOVE		=> Mask::new(IN_MOVED_FROM.value | IN_MOVED_TO.value, 'moved'),
		:IN_ALL_EVENTS	=> Mask::new(IN_ACCESS.value | IN_MODIFY.value | IN_ATTRIB.value | IN_CLOSE_WRITE.value | IN_CLOSE_NOWRITE.value | IN_OPEN.value | IN_MOVED_FROM.value | IN_MOVED_TO.value | IN_DELETE.value | IN_CREATE.value | IN_DELETE_SELF.value, 'all_events')
	}
	
	OrMasks.each {|key, value|
		const_set(key, value)
	}
	
	AllMasks = Masks.merge OrMasks
	
	require 'find'

	class INotify
		def initialize
			@wd_dir = Hash.new
			@dir_wd = Hash.new
			@io = IO.open(syscall(INOTIFY_INIT))
		end

		def close
			@io.close
		end

		def watch_dir (dir, option = IN_ALL_EVENTS)
			wd = syscall(INOTIFY_ADD_WATCH, @io.fileno, dir, option.value)
			
			if wd >= 0
				@dir_wd[dir] = wd
				@wd_dir[wd] = dir
			end
			
			return wd
      rescue Errno::EACCES => e
        STDERR.puts e.message
		end

		def ignore_dir (dir)
			syscall(INOTIFY_RM_WATCH, @io.fileno, @dir_wd[dir])
		end

		def watch_dir_recursively (dir, option = IN_ALL_EVENTS)
			Find.find(dir) { |sub_dir| watch_dir(sub_dir, option) if (File::directory?(sub_dir) == true) }
		end
		
		def ignore_dir_recursively (dir)
			Find.find(dir) { |sub_dir| ignore_dir(sub_dir) if (File::directory?(sub_dir) == true) }
		end
		
		def next_events
			begin
				read_cnt = @io.read(16)
				wd, mask, cookie, len = read_cnt.unpack('lLLL')
				read_cnt = @io.read(len)
				filename = read_cnt.unpack('Z*')
			end while (mask & IN_Q_OVERFLOW.value) != 0
			
			events = Array.new
	
			AllMasks.each_value do |m|
				next if m.value == IN_ALL_EVENTS.value
				events.push Event.new(@wd_dir[wd].to_s, filename.to_s, m.name.to_s, cookie) if (m.value & mask) != 0
			end
			
			return events
		end
		
		def each_event
			loop { next_events.each { |event| yield event } }
		end
		
		def start
			@thread = Thread.new { loop { next_events.each { |event| yield event } } }
		end
		
		def stop
			@thread.exit
		end
	end

	class Event
		attr_reader :path, :filename, :type, :cookie

		def initialize (path, filename, type, cookie)
			@path = path
			@filename = filename
			@type = type
			@cookie = cookie
		end

		def dump
			"path: " + @path.to_s + ", filename: " + @filename.to_s + ", type: " + @type.to_s + ", cookie: " + @cookie.to_s
		end

      def to_s
        dump
      end
	end
end
