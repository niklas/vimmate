plugin_dir = File.expand_path File.dirname(__FILE__) + '/plugins'

Dir["#{plugin_dir}/*/init.rb"].each do |plugin_init|
  ActiveSupport::Dependencies::load_paths << File.dirname(plugin_init)
  require_dependency plugin_init
end
