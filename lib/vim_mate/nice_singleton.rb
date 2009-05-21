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

require 'singleton'

module VimMate

  # A nicer singleton implementation. When a class mixes this module,
  # it becomes a singleton and you don't have to use 'instance' to
  # access the singleton's class method. For example:
  #   class Hello
  #     include VimMate::NiceSingleton
  #
  #     def hello
  #       "hello"
  #     end
  #   end
  #
  #   Hello.hello # => "hello"
  #
  module NiceSingleton
    def self.included(other)
      if other.class == Class
        other.send(:include, Singleton)
        class << other
          def method_missing(method, *args, &block)
            self.instance.send(method, *args)
          end
        end
      end
    end
  end
end
