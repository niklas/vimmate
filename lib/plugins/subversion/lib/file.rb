# All stuff for SVN handling of files

module VimMate
  module Plugin
    module SubversionFile
      def self.included(base)
        base.class_eval do
          include InstanceMethods
          modify_icon :svn do |file|
            Icons.overlay_with file.icon_name_without_svn, file.svn_icon, 'scm'
          end
        end
        $stderr.puts "Plugin Subversion loaded and applied to #{base}"
      end
      module InstanceMethods
        # Refresh the file. If the file status has changed, send a refresh
        # signal
        def refresh
          status = Subversion.status(@path)
          if @last_status != status
            @last_status = status
            ListedTree.refreshed self
          end
          self
        end

        
        # Return the icon for this file depending on the file status
        def svn_icon
          status = Subversion.status(@path)
          if @last_status != status
            @last_status = status
          end
          case status
          when Subversion::UNVERSIONED, Subversion::EXTERNAL,
               Subversion::IGNORED, Subversion::UNKNOWN
            nil
          when Subversion::NONE, Subversion::NORMAL
            "svn_normal"
          when Subversion::ADDED, Subversion::REPLACED
            'svn_added'
          when Subversion::DELETED, Subversion::MISSING
            'svn_deleted'
          when Subversion::MODIFIED
            'svn_modified'
          when Subversion::CONFLICTED
            'svn_conflict'
          when Subversion::MERGED, Subversion::OBSTRUCTED, Subversion::INCOMPLETE
            'svn_readonly'  # FIXME for now, have no better
          end
        end

        # Return the status text for this file depending on the file status
        def status_text
          Subversion.status_text(@path)
        end
      end
    end
  end
end
