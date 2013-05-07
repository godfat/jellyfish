
require 'jellyfish'



module Jellyfish
  module MultiActions
    def call env
      @env    = env
      actions = dispatch
      catch(:halt){
        actions[0...-1].each{ |route_block| block_call(*route_block) }
        body nil
        block_call(*actions.last)
      } || block_call(nil, nil) # respond the default if halted
    end

    def dispatch
      actions.map{ |(route, block)|
        case route
        when String
          [route, block] if route == path_info
        else#Regexp, using else allows you to use custom matcher
          match = route.match(path_info)
          [match, block] if match
        end
      }.compact
    end
  end
end
