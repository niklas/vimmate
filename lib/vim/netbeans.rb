module VimMate
  module Vim
    module Netbeans

      SERVER_MUTEX = Mutex.new

      class Message
        attr_reader :message
        def initialize(message)
          @message = message
        end

        def to_s
          @message
        end
      end
      class Event < Message
        attr_reader :buffer, :name, :value, :rest
        def initialize(message)
          super
          if match = message.match(/^(\d+):(\w+)=(\d)\s*/)
            @buffer = match[1].to_i
            @name =   match[2]
            @value =  match[3]
            @rest =   match.post_match.split(/\s/)
            @rest = @rest.map do |arg|
              case arg
              when /^"(.*)"$/
                $1
              when 'T'
                true
              when 'F'
                false
              when /^\d+$/
                arg.to_i
              else
                arg
              end
            end
          end
        end
        def to_s
          %Q~#{@buffer}:#{@name}=#{@value} #{@rest.inspect}~
        end
      end
      class Reply < Message
        attr_reader :seqno, :value
        def initialize(message)
          super
          @seqno, @value = message.split(/\s/)
          @seqno = @seqno.to_i
        end
      end

      def replies
        @replies ||= {}
      end

      def remember_reply(reply)
        replies[reply.seqno] = reply
      end

      def interpret_message(mess)
        if mess.index ':'
          event = Event.new(mess)
          case event.name
          when 'fileOpened'
            path = event.rest.first
            if event.buffer == 0
              send_command(new_buffer(path), 'putBufferNumber', path)
              send_command(last_buffer, 'startDocumentListen')
            else
              @buffers[event.buffer] = path
              send_command(event.buffer, 'startDocumentListen')
            end
          else
            mess
          end
          event
        else
          reply = Reply.new(mess)
          remember_reply reply
          reply
        end
      end

      attr_reader :port
      def server
        if @server
          @server
        else
          @server = TCPServer.open('localhost', 0)
          @port = @server.addr[1]
          @server
        end
      end

      def vim
        begin 
          @vim_session ||= server.accept_nonblock
        rescue Errno::EAGAIN, Errno::EWOULDBLOCK, Errno::ECONNABORTED, Errno::EPROTO, Errno::EINTR
          IO.select([server])
          retry
        end
        return @vim_session
      end

      attr_reader :seqno
      def new_seqno
        if @seqno
          @seqno += 1
        else
          @seqno = 1
        end
      end
      def send_command(buf,name,*args)
        command = %Q~#{buf}:#{name}!#{new_seqno}~
        unless args.empty?
          command << ' ' + args.map do |arg|
            case arg
            when String
              %Q~"#{arg.gsub('"','\\"')}"~
            when Array # lnum/col
              arg.length == 2 ? arg.join('/') : arg.join('-')
            when true
              'T'
            when false
              'F'
            else
              arg
            end
          end.join(' ')
        end
        send_message command
      end

      # TODO timeout
      def send_function(buf,name)
        seq = new_seqno
        send_message %Q~#{buf}:#{name}/#{seq}~
        while not reply = replies[seq]
          sleep 0.005
        end
        replies.delete(seq)
        reply
      end

      def send_message(message)
        STDERR.puts "--- NOT sending #{message}"
        return
        SERVER_MUTEX.synchronize do
          vim.puts message
        end
      end

    end
  end
end
