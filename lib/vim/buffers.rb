  module Vim
    module Buffers

      def buffers
        @buffers ||= [ nil ]
      end
      def new_buffer(path=nil)
        buffers << path
        buffers.length - 1
      end

      def last_buffer
        @buffers.length - 1
      end

    end
  end

