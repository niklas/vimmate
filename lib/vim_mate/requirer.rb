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

module VimMate

  # This module contains methods to help when requiring files that
  # could not be installed on the user computer.
  module Requirer

    # Runs the provided block if the file can be required. If it can't,
    # return the value of to_return_on_error
    def self.require_if(file, to_return_on_error = false)
      begin
        require file
      rescue LoadError
        to_return_on_error
      else
        yield
      end
    end

    # Runs the provided block if the file cannot be required. If it can,
    # return the value of to_return_on_success
    def self.require_not_if(file, to_return_on_success = false)
      begin
        require file
      rescue LoadError
        yield
      else
        to_return_on_success
      end
    end

    # Exit the program with a nice message if the specified file cannot
    # be required
    def self.require_exit(file)
      require file
    rescue LoadError
      puts "Module #{file} is required to run this program"
      exit
    end

    # Raise a LoadError if the provided block returns true
    def self.raise_load_error_if
      raise LoadError, "Requirer cannot continue"  if yield
    end
  end
end
