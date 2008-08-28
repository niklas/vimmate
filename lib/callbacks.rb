module VimMate
  module Callbacks
    def self.included(base)
      base.class_eval { extend ClassMethods}
    end
    module ClassMethods
      def has_callback before_or_after, meth
        name = "#{before_or_after}_#{meth}"
        list = "@@#{name}_hooks"
        filter = "filter_#{name}"
        class_eval <<-EOCODE
          #{list} = []
          def self.#{name}(&block)
            #{list} << block
          end
          def self.#{meth}(*args)
            args = #{filter}(*args) if respond_to?(:#{filter})
            #{list}.each do |hook|
              hook.call *args
            end
          end
          def self.run_#{name}_hooks(*args)
            #{list}.each do |hook|
              hook.call *args
            end
          end
        EOCODE
      end
    end
  end
end
