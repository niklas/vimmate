VimMate::Requirer.require_if('lib/subversion') do
  $stderr.puts "Loaded Subversion Support"
  require File.dirname(__FILE__) + '/lib/file'
  VimMate::ListedFile.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::ListedDirectory.class_eval { include VimMate::Plugin::SubversionFile }
end
