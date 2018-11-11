# frozen_string_literal: true

require 'jellyfish'

module Jellyfish
  class ChunkedBody
    include Enumerable
    attr_reader :body
    def initialize &body
      @body = body
    end

    def each &block
      if block
        body.call(block)
      else
        to_enum(:each)
      end
    end
  end
end
