
require 'jellyfish'
require 'jellyfish/multi_actions'
require 'jellyfish/normalized_params'
require 'jellyfish/normalized_path'

module Jellyfish
  module Sinatra
    include MultiActions
    include NormalizedParams
    include NormalizedPath
  end
end
