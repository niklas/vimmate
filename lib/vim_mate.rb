module VimMate
end

$:.unshift File.dirname(__FILE__)

require 'vim_mate/requirer'
require 'vim_mate/nice_singleton'
require 'vim_mate/vim_widget'
require 'vim_mate/config'
require 'vim_mate/icons'
require 'vim_mate/plugins'
require 'vim_mate/app'
