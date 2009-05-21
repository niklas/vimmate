module VimMate
  module Plugin
    module INotifyDirectory
      Mask = INotify::Mask.new(
        INotify::IN_MODIFY.value | 
        INotify::IN_DELETE.value | 
        INotify::IN_CREATE.value | 
        INotify::IN_MOVED_TO.value |
        INotify::IN_MOVED_FROM.value |
        0, 'filechange')
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          extend ClassMethods
          alias_method :initialize_without_inotify, :initialize
          alias_method :initialize, :initialize_with_inotify
          #alias_method_chain :initialize, :notify
          start_inotify_watcher
        end
        
      end

      module InstanceMethods
        def initialize_with_inotify(*args)
          initialize_without_inotify(*args)
          # TODO need sematically better condition
          unless tree.has_path? full_path
            self.class.inotify_watcher.watch_dir(self.full_path, Mask) if directory?
          end
        end
      end

      module ClassMethods
        def inotify_watcher
          @@inotify_watcher ||= INotify::INotify.new
        end

        def start_inotify_watcher
          inotify_watcher.start do |event|
            next if ignore_file_changes? event.filename
            path = File.join(event.path, event.filename)
            case event.type  
            when 'modify'
              Signal.emit_file_modified(path)
            when /^delete|moved_from$/
              Signal.emit_file_deleted(path)
            when /^create|moved_to$/
              Signal.emit_file_created(path)
            end
          end
        end

        def ignore_file_changes?(filename)
          exclusions = [ /(swp|~|rej|orig)$/, /\/\.?#/, /^\./ ]
          exclusions.any? { |exclusion| filename =~ exclusion }
        end
      end
    end
  end
end
