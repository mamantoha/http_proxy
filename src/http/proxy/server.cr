require "./server/handler"
require "./server/basic_auth"

# A concurrent Proxy server implementation.
#
# ```
# require "http_proxy"
#
# server = HTTP::Proxy::Server.new
# address = server.bind_tcp("127.0.0.1", 8080)
# puts "Listening on http://#{address}"
# server.listen
# ```
#
class HTTP::Proxy::Server
  Log = ::Log.for("http.proxy.server")

  @sockets = [] of Socket::Server

  # Returns `true` if this server is closed.
  getter? closed : Bool = false

  # Returns `true` if this server is listening on its sockets.
  getter? listening : Bool = false

  # Creates a new HTTP Proxy server
  def initialize
    handler = build_middleware

    @processor = HTTP::Server::RequestProcessor.new(handler)
  end

  # Creates a new HTTP Proxy server with the given block as handler.
  def initialize(&handler : Context ->)
    @processor = HTTP::Server::RequestProcessor.new(handler)
  end

  # Creates a new HTTP Proxy server with a handler chain constructed from the *handlers*
  # array and the given block.
  def initialize(handlers : Indexable(HTTP::Handler), &handler : Context ->)
    handler = build_middleware(handlers, handler)

    @processor = HTTP::Server::RequestProcessor.new(handler)
  end

  # Creates a new HTTP Proxy server with the *handlers* array as handler chain.
  def initialize(handlers : Indexable(HTTP::Handler))
    handler = build_middleware(handlers)

    @processor = HTTP::Server::RequestProcessor.new(handler)
  end

  # Creates a new HTTP server with the given *handler*.
  def initialize(handler : HTTP::Handler | HTTP::Handler::HandlerProc)
    @processor = HTTP::Server::RequestProcessor.new(handler)
  end

  private def build_middleware(handler : (Context ->)? = nil)
    proxy_handler = Handler.new
    proxy_handler.next = handler if handler
    proxy_handler
  end

  private def build_middleware(handlers, last_handler : (Context ->)? = nil)
    proxy_handler = build_middleware(last_handler)
    return proxy_handler if handlers.empty?

    0.upto(handlers.size - 2) { |i| handlers[i].next = handlers[i + 1] }
    handlers.last.next = proxy_handler if proxy_handler
    handlers.first
  end

  # Creates a `TCPServer` listening on `host:port` and adds it as a socket, returning the local address
  # and port the server listens on.
  #
  # If *reuse_port* is `true`, it enables the `SO_REUSEPORT` socket option,
  # which allows multiple processes to bind to the same port.
  def bind_tcp(host : String, port : Int32, reuse_port : Bool = false) : Socket::IPAddress
    tcp_server = TCPServer.new(host, port, reuse_port: reuse_port)

    begin
      bind(tcp_server)
    rescue exc
      tcp_server.close
      raise exc
    end

    tcp_server.local_address
  end

  # Adds a `Socket::Server` *socket* to this server.
  def bind(socket : Socket::Server) : Nil
    raise "Can't add socket to running server" if listening?
    raise "Can't add socket to closed server" if closed?

    @sockets << socket
  end

  # Overwrite this method to implement an alternative concurrency handler
  # one example could be the use of a fiber pool
  protected def dispatch(io)
    spawn handle_client(io)
  end

  # Starts the server. Blocks until the server is closed.
  def listen : Nil
    raise "Can't re-start closed server" if closed?
    raise "Can't start server with no sockets to listen to, use HTTP::Server::Proxy#bind first" if @sockets.empty?
    raise "Can't start running server" if listening?

    @listening = true
    done = Channel(Nil).new

    @sockets.each do |socket|
      spawn do
        loop do
          io = begin
            socket.accept?
          rescue e
            handle_exception(e)
            next
          end

          if io
            dispatch(io)
          else
            break
          end
        end
      ensure
        done.send nil
      end
    end

    @sockets.size.times { done.receive }
  end

  # Gracefully terminates the server. It will process currently accepted
  # requests, but it won't accept new connections.
  def close : Nil
    raise "Can't close server, it's already closed" if closed?

    @closed = true
    @processor.close

    @sockets.each do |socket|
      socket.close
    rescue
      # ignore exception on close
    end

    @listening = false
    @sockets.clear
  end

  private def handle_client(io : IO)
    if io.is_a?(IO::Buffered)
      io.sync = false
    end

    {% unless flag?(:without_openssl) %}
      if io.is_a?(OpenSSL::SSL::Socket::Server)
        begin
          io.accept
        rescue ex
          Log.debug(exception: ex) { "Error during SSL handshake" }
          return
        end
      end
    {% end %}

    @processor.process(io, io)
  ensure
    {% begin %}
      begin
        io.close
      rescue IO::Error{% unless flag?(:without_openssl) %} | OpenSSL::SSL::Error{% end %}
      end
    {% end %}
  end

  # This method handles exceptions raised at `Socket#accept?`.
  private def handle_exception(e : Exception)
    Log.error(exception: e) { "Error while connecting a new socket" }
  end
end
