require 'rubygems'
require 'activesupport'


#ActiveSupport::Dependencies::logger = Logger.new(STDERR)
#ActiveSupport::Dependencies::log_activity = true
ActiveSupport::Dependencies::load_paths << File.expand_path(File.join(File.dirname(__FILE__), "../lib"))
ActiveSupport::Dependencies::load_paths << File.expand_path(File.join(File.dirname(__FILE__), "../controllers"))
ActiveSupport::Dependencies::load_paths << File.expand_path(File.join(File.dirname(__FILE__), "../lib/vim_mate"))

VimMate::Requirer.require_exit('gtk2')
VimMate::Requirer.require_exit('libglade2')

Config = VimMate::Config

#require_dependency 'config'
#require 'vimmatelib/file_tree_view'
require_dependency 'gtk_thread_helper'
require_dependency 'plugins'

require_dependency 'active_window'
require_dependency 'vim_mate_controller'
require_dependency 'file_filter_controller'
