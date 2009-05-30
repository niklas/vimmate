module ActiveWindow
  class Signal
    class UnknownSignalError < StandardError ; end
    @@signals = {}

    def self.on(name, &block)
      @@signals[name] ||= []
      @@signals[name] << block
    end

    def self.emit(name, *args)
      if @@signals[name].is_a?(Array)
        @@signals[name].each do |block|
          block.call(*args)
        end
      end
    end

    def self.signals
      @@signals
    end

    def self.define name
      class_eval <<-EOCODE
        def self.emit_#{name}(*args)
          self.emit(:#{name},*args)
        end
        def self.on_#{name}(&block)
          self.on(:#{name}, &block)
        end
      EOCODE
    end

    def self.method_missing(meth,*args,&block)
      case meth.to_s
      when /^emit_(.*)$/
        raise UnknownSignalError, "cannot emit unknown signal '#{$1}'"
      when /^on_(.*)$/
        raise UnknownSignalError, "cannot connect to unknown signal '#{$1}'"
      else
        raise NoMethodError, "unknown method: #{meth}"
      end
    end
    
  end
end
