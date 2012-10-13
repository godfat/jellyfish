
require 'jellyfish'
require 'rack/request'

module Jellyfish
  class Sinatra < Controller
    attr_reader :request, :params
    def block_call argument, block
      @request = Rack::Request.new(env)
      @params  = indifferent_params(if argument.kind_of?(MatchData)
      then # merge captured data from matcher into params as sinatra
        request.params.merge(Hash[argument.names.zip(argument.captures)])
      else
        request.params
      end)

      super
    end

    private
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
  end
end
