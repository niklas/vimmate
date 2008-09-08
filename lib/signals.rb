module VimMate
  class Signals
    #include Singleton

    @@signals = {}

    def self.connect(signal, &block)
      @@signals[signal] ||= []
      @@signals[signal] << block
    end

    def self.emit(signal, *args)
      if @@signals[signal].is_a?(Array)
        @@signals[signal].each do |block|
          block.call(args)
        end
      end
    end

  end
end
