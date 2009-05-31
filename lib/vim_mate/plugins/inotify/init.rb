require_dependency 'lib/INotify'
require_dependency 'lib/directory'
ListedDirectory.class_eval { include VimMate::Plugin::INotifyDirectory }

