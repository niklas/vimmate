require 'rubygems'
require 'activesupport'


APP_ROOT = File.expand_path( File.join( File.dirname(__FILE__), '..'  ) )
PROGRAM_NAME = 'vim_mate'

#ActiveSupport::Dependencies::logger = Logger.new( File.expand_path('log/dependencies.log') )
#ActiveSupport::Dependencies::log_activity = true
ActiveSupport::Dependencies::load_paths << File.join(APP_ROOT, "lib")
ActiveSupport::Dependencies::load_paths << File.join(APP_ROOT, "controllers")
ActiveSupport::Dependencies::load_paths << File.join(APP_ROOT, "lib/vim_mate")

VimMate::Requirer.require_exit('gtk2')
VimMate::Requirer.require_exit('libglade2')


#require 'vimmatelib/file_tree_view'
require_dependency 'gtk_thread_helper'
require_dependency 'plugins'

require_dependency 'active_window'

%w(
  file_created file_modified file_deleted file_opened
  dir_created
  item_opened item_removed item_refreshed
  file_opened
).each do |signal|
  ActiveWindow::Signal::define signal
end

Dir[File.join(APP_ROOT, 'controllers', '*_controller.rb' )].each do |controller_path|
  require_dependency File.basename(controller_path)
end
