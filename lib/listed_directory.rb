module VimMate
  class ListedDirectory < ListedFile
    def directory?
      true
    end
    def file?
      false # yeah..!
    end
  end
end
