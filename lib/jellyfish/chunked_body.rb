
require 'jellyfish'

module Jellyfish
  class ChunkedBody
    attr_reader :body
    def initialize &body
      @body = body
    end

    def each &block
      body.call(block)
    end
  end
end
