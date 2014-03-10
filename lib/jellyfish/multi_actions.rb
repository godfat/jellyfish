
require 'jellyfish'



module Jellyfish
  module MultiActions
    def call env
      @env = env
      dispatch.inject(nil){ |_, route_block| block_call(*route_block) }
    end

    def dispatch
      acts = actions.map{ |(route, block)|
        case route
        when String
          [route, block] if route == path_info
        else#Regexp, using else allows you to use custom matcher
          match = route.match(path_info)
          [match, block] if match
        end
      }.compact

      if acts.empty?
        action_missing
      else
        acts
      end
    end
  end
end
