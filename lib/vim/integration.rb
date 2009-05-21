require 'socket'

module Vim
  module Integration

    Password = 'donthasslethehoff'

    include Buffers
    include Netbeans

    private
    def listen
      Thread.new do
        while true
          send_function(0, 'getCursor')
          sleep 1
        end
      end
      Thread.new do
        while true
          if data = vim.gets
            interpret_message(data)
          end
        end
      end
    end

    def exec_gvim(command)
      `gvim --servername #{@vim_server_name} #{command}`
    end

    def remote_send(command)
      exec_gvim %Q~--remote-send '#{command.gsub(%q~'~,%q~\\'~)}'~
    end
  end
end
