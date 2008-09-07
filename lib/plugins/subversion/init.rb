VimMate::Requirer.require_if('lib/subversion') do
  $stderr.puts "Loaded Subversion Support"
  require 'lib/file'
  require 'lib/menu'
  VimMate::ListedFile.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::ListedDirectory.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::FilesMenu.class_eval { include VimMate::Plugin::SubversionMenu }
end
