require 'rubygems'

APP_ROOT = File.expand_path( File.join( File.dirname(__FILE__), '..'  ) )
PROGRAM_NAME = 'vim_mate'

# for reverse_merge!
require 'active_support/core_ext/object'

$:.unshift APP_ROOT

require 'lib/active_window'
require 'lib/listed_file'
require 'lib/listed_directory'
require 'lib/file_tree_store.rb'
require 'lib/filtered_file_tree_store.rb'
require 'lib/vim'
require 'lib/vim_mate'


require 'gtk_thread_helper'

%w(
  file_created file_modified file_deleted file_opened
  dir_created
  item_opened item_removed item_refreshed
  file_opened
).each do |signal|
  ActiveWindow::Signal::define signal
end

Dir[File.join(APP_ROOT, 'controllers', '*_controller.rb' )].each do |controller_path|
  require controller_path
end
