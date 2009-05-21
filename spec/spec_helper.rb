require 'config/environment'

def iter_mock
  mock(:[] => 'value', :[]= => true)
end

def tree_mock
  mock(:has_path? => true) # so that inotify is not called
end

