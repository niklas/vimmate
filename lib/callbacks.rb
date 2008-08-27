module VimMate
  module Callbacks
    def self.included(base)
      base.class_eval { extend ClassMethods}
    end
    module ClassMethods
      def has_callback before_or_after, meth
        list = "@@#{before_or_after}_#{meth}_hooks"
        class_eval <<-EOCODE
          #{list} = []
          def self.#{before_or_after}_#{meth}(&block)
            #{list} << block
          end
          def self.#{meth}(*args)
            #{list}.each do |hook|
              hook.call *args
            end
          end
        EOCODE
      end
    end
  end
end
