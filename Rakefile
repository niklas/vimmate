=begin
= VimMate: Vim graphical add-on
Copyright (c) 2006 Guillaume Benny

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
=end

require 'rake/gempackagetask'
require 'rake/rdoctask'

require './lib/vim_mate/version.rb'

task :default => :package

# Documentation Task
Rake::RDocTask.new("rdoc") do |t|
  t.rdoc_files.include('README',
                       'COPYING',
                       'TODO',
                       'CHANGELOG',
                       'bin/**',
                       'lib/**/*.rb')
  t.main = 'README'
  t.title = "VimMate #{VimMate::VERSION} documentation"
end

# Gem Specification
gem_specification = Gem::Specification.new do |s|
  s.name = 'VimMate'
  s.version = VimMate::VERSION
  s.author = 'Guillaume Benny'
  s.homepage = 'http://vimmate.rubyforge.org'
  s.summary = 'VimMate is a graphical add-on to Vim with IDE-like features.'

  s.executables = ['vimmate']

  s.files = FileList['README',
                     'COPYING',
                     'TODO',
                     'CHANGELOG',
                     'Rakefile',
                     'setup.rb',
                     'bin/**/*',
                     'lib/**/*',
                     'images/**/*']
end

# Gem Task
Rake::GemPackageTask.new(gem_specification) do |pkg|
  pkg.need_zip = false
  pkg.need_tar = true
end
task :package => [:rdoc]

desc 'Remove rdoc and package'
task :clobber => [:clobber_rdoc, :clobber_package]

desc 'Upload rdoc to Rubyforge'
task :upload_rdoc => [:add_tracker] do
  sh "scp -r html bennygui@rubyforge.org:/var/www/gforge-projects/vimmate"
end

desc 'Add google tracker'
task :add_tracker => [:rdoc] do
  Dir['html/**/*.html'].each do |file|
    h = File.read(file).sub(/<\/body>/, <<-EOS)
      <script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
      </script>
      <script type='text/javascript'>
      //<![CDATA[
      _uacct = "UA-2894512-3";
      if (typeof(window['urchinTracker']) != "undefined") { urchinTracker(); }
      //]]>
      </script>		
      </body>
    EOS
    open(file, 'w') do |f|
      f.write(h)
    end
  end
end
