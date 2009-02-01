require 'socket'
require 'vim/buffers'
require 'vim/netbeans'

module VimMate
  module VimIntegration

    Password = 'donthasslethehoff'

    include Vim::Buffers
    include Vim::Netbeans

    private
    def listen
      Thread.new do
        while true
          STDERR.puts "getCursor: #{send_function(0, 'getCursor')}"
          sleep 1
        end
      end
      Thread.new do
        while true
          if data = vim.gets
            STDERR.puts "Vim: #{interpret_message(data)}"
          else
            STDERR.puts "nothing---"
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
