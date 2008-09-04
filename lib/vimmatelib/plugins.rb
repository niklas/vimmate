require 'requirer'
plugin_dir = File.expand_path File.dirname(__FILE__) + '/../plugins'
Dir["#{plugin_dir}/*/init.rb"].each do |plugin_init|
  require plugin_init
end
