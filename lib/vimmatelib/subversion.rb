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

require 'svn/core'
require 'svn/client'
require 'svn/wc'
require 'svn/repos'
require 'vimmatelib/config'
require 'vimmatelib/nice_singleton'
require 'vimmatelib/requirer'

module VimMate
  
  # Do not load Subversion if it's disabled
  Requirer.raise_load_error_if do
    not Config[:subversion_enabled]
  end

  # This class helps the integration of the Subversion version control system
  class Subversion
    include NiceSingleton

    UNKNOWN = -1
    NONE = 1
    UNVERSIONED = 2
    NORMAL = 3
    ADDED = 4
    MISSING = 5
    DELETED = 6
    REPLACED = 7
    MODIFIED = 8
    MERGED = 9
    CONFLICTED = 10
    IGNORED = 11
    OBSTRUCTED = 12
    EXTERNAL = 13
    INCOMPLETE = 14

    STATUS_TEXT = {
      UNKNOWN => "",
      NONE => "None",
      UNVERSIONED => "Unversioned",
      NORMAL => "Normal",
      ADDED => "Added",
      MISSING => "Missing",
      DELETED => "Deleted",
      REPLACED => "Replaced",
      MODIFIED => "Modified",
      MERGED => "Merged",
      CONFLICTED => "Conflicted",
      IGNORED => "Ignored",
      OBSTRUCTED => "Obstructed",
      EXTERNAL => "External",
      INCOMPLETE => "Incomplete",
    }.freeze

    # Create the Subversion class. Cannot be called directly
    def initialize
    end

    # Get the status of the specified file. The file must be a full path.
    def status(path)
      ret_status = UNKNOWN
      begin
      # Arguments: File, Revision, Recursive, Any files, Update
      new_client.status(path, "HEAD", true, true, false) do |path, status|
        ret_status = status.text_status if status.text_status > ret_status
      end
      rescue Svn::Error::WC_NOT_DIRECTORY
      end
      ret_status
    end

    # Get the text that represents the status of the file
    def status_text(path)
      STATUS_TEXT[status(path)]
    end

    # Add the specified file (full path) to Subversion
    def add(path)
      cleanup(path)
      new_client.add(path)
    rescue
      false
    else
      true
    end

    # Remove the specified file (full path) from Subversion's control
    def remove(path)
      cleanup(path)
      new_client.remove(path)
    rescue
      false
    else
      true
    end

    # Revert the specified file (full path) to what it was before the local
    # modifications
    def revert(path)
      cleanup(path)
      new_client.revert(path)
    rescue
      false
    else
      true
    end

    # Move the specified file (full path) to a new file name
    def move(path, new_path)
      cleanup(path)
      new_client.move(path, new_path)
    rescue
      false
    else
      true
    end
    
    # Cleanup the subversion path when something is locked
    def cleanup(path)
      new_client.cleanup(File.directory?(path) ? path : File.dirname(path))
    rescue
      false
    else
      true
    end
    
    private

    # Create a new subversion client
    def new_client
      Svn::Client::Context.new
    end
    
  end
end
