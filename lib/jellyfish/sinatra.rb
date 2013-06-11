
require 'jellyfish'
require 'jellyfish/indifferent_params'
require 'jellyfish/multi_actions'

module Jellyfish
  module Sinatra
    include IndifferentParams
    include MultiActions
    include NormalizedPath
  end
end
