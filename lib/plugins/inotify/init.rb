require File.dirname(__FILE__) + '/lib/INotify'
require File.dirname(__FILE__) + '/lib/directory'
VimMate::ListedDirectory.class_eval { include VimMate::Plugin::INotifyDirectory }

