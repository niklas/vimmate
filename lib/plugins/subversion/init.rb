VimMate::Requirer.require_if('lib/subversion') do
  require 'lib/file'
  require 'lib/menu'
  VimMate::ListedFile.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::ListedDirectory.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::FilesMenu.class_eval { include VimMate::Plugin::SubversionMenu }
end
