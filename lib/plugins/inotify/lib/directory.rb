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
          self.class.inotify_watcher.watch_dir(self.full_path, Mask) if directory?
          self.class.add_tree_for_notify(self.tree)
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
              @@trees_to_notify.each {|tree| tree.refresh_path(path) }
            when 'delete'
              @@trees_to_notify.each {|tree| tree.remove_path(path) }
            when /^create|moved_to$/
              @@trees_to_notify.each {|tree| tree.add_path(path) }
            end
          end
        end
        def add_tree_for_notify(tree)
          @@trees_to_notify ||= Set.new
          @@trees_to_notify << tree unless tree.nil?
        end
        def ignore_file_changes?(filename)
          exclusions = [ /(swp|~|rej|orig)$/, /\/\.?#/, /^\./ ]
          exclusions.any? { |exclusion| filename =~ exclusion }
        end
      end
    end
  end
end
