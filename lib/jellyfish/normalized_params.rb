
require 'jellyfish'
require 'rack/request'


module Jellyfish
  module NormalizedParams
    attr_reader :params
    def block_call argument, block
      initialize_params(argument)
      super
    end

    private
    def initialize_params argument
      @params = force_encoding(indifferent_params(
      if argument.kind_of?(MatchData)
        # merge captured data from matcher into params as sinatra
        request.params.merge(Hash[argument.names.zip(argument.captures)])
      else
        request.params
      end))
    end

    # stolen from sinatra
    # Enable string or symbol key access to the nested params hash.
    def indifferent_params(params)
      params = indifferent_hash.merge(params)
      params.each do |key, value|
        next unless value.is_a?(Hash)
        params[key] = indifferent_params(value)
      end
    end

    # stolen from sinatra
    # Creates a Hash with indifferent access.
    def indifferent_hash
      Hash.new {|hash,key| hash[key.to_s] if Symbol === key }
    end

    # stolen from sinatra
    # Fixes encoding issues by casting params to Encoding.default_external
    def force_encoding(data, encoding=Encoding.default_external)
      return data if data.respond_to?(:rewind) # e.g. Tempfile, File, etc
      if data.respond_to?(:force_encoding)
        data.force_encoding(encoding).encode!
      elsif data.respond_to?(:each_value)
        data.each_value{ |v| force_encoding(v, encoding) }
      elsif data.respond_to?(:each)
        data.each{ |v| force_encoding(v, encoding) }
      end
      data
    end
  end
end
