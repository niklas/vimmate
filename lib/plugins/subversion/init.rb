#Requirer.require_if('vimmatelib/subversion') do
  require 'vimmatelib/subversion'
  require File.dirname(__FILE__) + '/lib/file'
  VimMate::ListedFile.class_eval { include VimMate::Plugin::SubversionFile }
  VimMate::ListedDirectory.class_eval { include VimMate::Plugin::SubversionFile }
#end
