VimMate::Requirer.require_if 'lib/INotify' do
  require 'lib/directory'
  VimMate::ListedDirectory.class_eval { include VimMate::Plugin::INotifyDirectory }
end

