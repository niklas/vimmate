begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name =        %q{vimmate}
    gemspec.summary =     %q{VimMate is a graphical add-on to Vim with IDE-like features.}
    gemspec.description = %q{
      VimMate is a graphical add-on to Vim with IDE-like features: it does more
      than the plain Vim while still being lightweight. Even with the additional
      features, it stays out of the way for it's main task: editing files with Vim.
      VimMate adds functionality to Vim by embedding Vim GTK GUI (gVim) within
      VimMate.
    }
    gemspec.email =       %q{niklas+vimmate@lanpartei.de}
    gemspec.homepage =    %q{http://github.com/niklas/vimmate/}
    gemspec.authors =     ["Guillaume Benny", "Niklas Hofer", "Stefan Bethge"]
    gemspec.executables = %w{vimmate}
    gemspec.require_paths = ["lib"]


    # TODO docs would be nice, indeed
    gemspec.has_rdoc = false

  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end
