require 'lib/INotify'
require 'lib/directory'

# FIXME current inotify implementation uses syscall
#       syscall is not implemented in Ruby 1.9 on 64bit systems, see:
#       * https://github.com/ruby/ruby/blob/ruby_1_9_2/io.c#L7529
#       * https://github.com/ruby/ruby/commit/5a809d60bd3ea54474e34f897ae60b1ae78bab73#L0R6981
#       * http://blade.nagaokaut.ac.jp/cgi-bin/scat.rb/ruby/ruby-core/8722

if Kernel.respond_to?(:syscall)
  ListedDirectory.class_eval { include VimMate::Plugin::INotifyDirectory }
end

