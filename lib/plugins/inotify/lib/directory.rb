module VimMate
  module Plugin
    module INotifyDirectory
      Mask = INotify::Mask.new(INotify::IN_MODIFY.value | INotify::IN_DELETE.value | INotify::IN_CREATE.value | INotify::IN_MOVED_TO.value, 'filechange')
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          extend ClassMethods
          alias_method :initialize_without_inotify, :initialize
          alias_method :initialize, :initialize_with_inotify
          start_inotify_watcher
        end
        
      end

      module InstanceMethods
        def initialize_with_inotify(*args)
          initialize_without_inotify(*args)
          self.class.inotify_watcher.watch_dir self.path, Mask
        end
      end

      module ClassMethods
        def inotify_watcher
          @inotify_watcher ||= INotify::INotify.new
        end
        def start_inotify_watcher
          inotify_watcher.start do |event|
            next if ignore_file_changes? event.filename
            $stderr.puts "Inotify Event: #{event.dump}"
            case event.type
            when /^modify|moved_to$/
              $stderr.puts "Inotify: got modified: #{event.filename}"
              ListedTree.refreshed File.join(event.path,event.filename)
            when 'delete'
              $stderr.puts "Inotify: got deleted: #{event.filename}"
              ListedTree.removed File.join(event.path,event.filename)
            when 'create'
              $stderr.puts "Inotify: got created: #{event.filename}"
              ListedTree.added File.join(event.path,event.filename)
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
