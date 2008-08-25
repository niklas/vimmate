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

require 'gtk2'
require 'vimmatelib/config'
require 'vimmatelib/tags_window'

module VimMate

  class SidebarWindow
    def initialize(files_window, vim)
      
      @gtk_notebook = Gtk::Notebook.new()

      @gtk_notebook.tab_pos=Gtk::POS_LEFT

      files_label = Gtk::Label.new("Files", true)
      files_label.set_angle(90)

      @gtk_notebook.append_page(files_window, files_label)

      @tags_window = VimMate::TagsWindow.new(vim)
      tags_label = Gtk::Label.new("Tags", true)
      tags_label.set_angle(90)

      @gtk_notebook.append_page(@tags_window.gtk_window, tags_label)
    end
    
    # The "window" for this object
    def gtk_window
      @gtk_notebook
    end

  end
end
