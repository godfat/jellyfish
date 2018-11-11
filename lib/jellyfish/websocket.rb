# frozen_string_literal: true

require 'jellyfish'
require 'websocket_parser'
require 'digest/sha1'

module Jellyfish
  module WebSocket
    ::WebSocket.constants.each do |const|
      const_set(const, ::WebSocket.const_get(const))
    end

    attr_reader :sock, :parser

    def switch_protocol &block
      key = env['HTTP_SEC_WEBSOCKET_KEY']
      accept = [Digest::SHA1.digest("#{key}#{GUID}")].pack('m0')
      @sock = env['rack.hijack'].call
      sock.binmode
      sock.write(<<-HTTP)
HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: #{accept}\r
\r
      HTTP
      @parser = Parser.new
      parser.on_message(&block)
    end

    def ws_start
      while !sock.closed? && IO.select([sock]) do
        ws_read
      end
    end

    def ws_read bytes=8192
      parser << sock.readpartial(bytes)
    rescue EOFError
      sock.close
    end

    def ws_write msg
      sock << Message.new(msg).to_data
    end

    def ws_close
      sock << Message.close.to_data
      sock.close
    end
  end
end
