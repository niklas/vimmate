
  class Signal
#    include NiceSingleton
    class UnknownSignalError < StandardError ; end

    def initialize
      @signals = {}
    end

    def on(name, &block)
      @signals[name] ||= []
      @signals[name] << block
    end

    def emit(name, *args)
      if @signals[name].is_a?(Array)
        @signals[name].each do |block|
          block.call(*args)
        end
      end
    end

    def define name
      class_eval <<-EOCODE
        def emit_#{name}(*args)
          emit(:#{name},*args)
        end
        def on_#{name}(&block)
          on(:#{name}, &block)
        end
      EOCODE
    end

    def method_missing(meth,*args,&block)
      case meth.to_s
      when /^emit_(.*)$/
        raise UnknownSignalError, "cannot emit unknown signal '#{$1}'"
      when /^on_(.*)$/
        raise UnknownSignalError, "cannot connect to unknown signal '#{$1}'"
      else
        raise NoMethodError, "unknown method: #{meth}"
      end
    end
    
    define :file_created
    define :file_modified
    define :file_deleted
    define :file_opened

  end
