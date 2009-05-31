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

      Exclusions = [ /(swp|~|rej|orig)$/, /\/\.?#/, /^\./ ]
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          extend ClassMethods
          alias_method_chain :initialize, :inotify
          start_inotify_watcher
        end
        
      end

      module InstanceMethods
        def initialize_with_inotify(*args)
          initialize_without_inotify(*args)
          if directory?
            self.class.inotify_watcher.watch_dir(full_path, Mask)
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
              ActiveWindow::Signal.emit_file_modified(path)
            when /^delete|moved_from$/
              ActiveWindow::Signal.emit_file_deleted(path)
            when /^create|moved_to$/
              ActiveWindow::Signal.emit_file_created(path)
            end
          end
        end

        def ignore_file_changes?(filename)
          Exclusions.any? { |exclusion| filename =~ exclusion }
        end
      end
    end
  end
end
