
require 'jellyfish'

module Jellyfish
  class ChunkedBody
    include Enumerable
    attr_reader :body
    def initialize &body
      @body = body
    end

    def each &block
      body.call(block)
    end
  end
end
