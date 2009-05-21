require 'rubygems'
require 'activesupport'


module VimMate
end
#ActiveSupport::Dependencies::logger = Logger.new(STDERR)
#ActiveSupport::Dependencies::log_activity = true
ActiveSupport::Dependencies::load_paths << File.join(File.dirname(__FILE__), "../lib")
ActiveSupport::Dependencies::load_paths << File.join(File.dirname(__FILE__), "../lib/vim_mate")

require_dependency 'requirer'
require_dependency 'try'

VimMate::Requirer.require_exit('gtk2')
VimMate::Requirer.require_exit('libglade2')
require_dependency 'version'
require_dependency 'config'
require_dependency 'active_window/base'
require_dependency 'dummy_window'
require_dependency 'files_menu'
require_dependency 'icons'
require_dependency 'search_window'
#require 'vimmatelib/file_tree_view'
require_dependency 'file_tree_controller'
require_dependency 'signals'
require_dependency 'plugins'
require_dependency 'vim/integration'
require_dependency 'vim_window'
require_dependency 'tags_window'
require_dependency 'search_window'
require_dependency 'config_window'
require_dependency 'gtk_thread_helper'
