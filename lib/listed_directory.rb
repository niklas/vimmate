require 'listed_file'
module VimMate
  class ListedDirectory < ListedFile
    def file?
      false # yeah..!
    end
  end
end
