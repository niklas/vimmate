# All stuff for SVN handling of files

module VimMate
  module Plugin
    module SubversionItem
      module InstanceMethods
        # Refresh the file. If the file status has changed, send a refresh
        # signal
        def refresh
          status = Subversion.status(@path)
          if @last_status != status
            @last_status = status
            @tree_signal.call(:refresh, self)
          end
          self
        end
        
        # Return the icon for this file depending on the file status
        def icon
          status = Subversion.status(@path)
          if @last_status != status
            @last_status = status
          end
          case status
          when Subversion::UNVERSIONED, Subversion::EXTERNAL,
               Subversion::IGNORED, Subversion::UNKNOWN
            Icons.send("#{icon_type}_icon")
          when Subversion::NONE, Subversion::NORMAL
            Icons.send("#{icon_type}_green_icon")
          when Subversion::ADDED, Subversion::DELETED,
               Subversion::REPLACED, Subversion::MODIFIED
            Icons.send("#{icon_type}_orange_icon")
          when Subversion::MISSING, Subversion::MERGED,
               Subversion::CONFLICTED, Subversion::OBSTRUCTED,
               Subversion::INCOMPLETE
            Icons.send("#{icon_type}_red_icon")
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
