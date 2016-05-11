
require 'jellyfish/test'
require 'stringio'

describe Jellyfish::WebSocket do
  paste :stringio

  after do
    Muack.verify
  end

  app = Class.new do
    include Jellyfish
    controller_include Jellyfish::WebSocket
    get '/echo' do
      switch_protocol do |msg|
        ws_write(msg)
      end
      ws_write('ping')
      ws_start
    end
  end.new

  def create_env
    sock = StringIO.new
    sock.set_encoding('ASCII-8BIT')
    mock(IO).select([sock]) do # or EOFError, not sure why?
      sock << WebSocket::Message.new('pong').to_data * 2
      [[sock], [], []]
    end
    [{'REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/echo',
      'rack.hijack' => lambda{ sock }}, sock]
  end

  would 'ping pong' do
    env, sock = create_env
    app.call(env)
    sock.string.should.eq <<-HTTP.chomp.force_encoding('ASCII-8BIT')
HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: Kfh9QIsMVZcl6xEPYxPHzW8SZ8w=\r
\r
\x81\x04ping\x81\x04pong\x81\x04pong
    HTTP
  end
end
