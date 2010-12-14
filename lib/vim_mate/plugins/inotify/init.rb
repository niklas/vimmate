require 'lib/INotify'
require 'lib/directory'
ListedDirectory.class_eval { include VimMate::Plugin::INotifyDirectory }

