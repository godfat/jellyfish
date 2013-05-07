
require 'jellyfish'



module Jellyfish
  module MultiActions
    Identity = lambda{|_|_}

    def call env
      @env = env
      acts = dispatch
      catch(:halt){
        acts[0...-1].each{ |route_block| block_call(*route_block) }
        body nil
        block_call(*acts.last)
      } || block_call(nil, Identity) # respond the default if halted
    end

    def dispatch
      ret = actions.map{ |(route, block)|
        case route
        when String
          [route, block] if route == path_info
        else#Regexp, using else allows you to use custom matcher
          match = route.match(path_info)
          [match, block] if match
        end
      }.compact

      if ret.empty?
        raise(Jellyfish::NotFound.new)
      else
        ret
      end
    end
  end
end
