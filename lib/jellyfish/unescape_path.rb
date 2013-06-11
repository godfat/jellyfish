
require 'jellyfish'
require 'uri'


module Jellyfish
  module UnescapePath
    def path_info
      URI.decode_www_form_component(super, Encoding.default_external)
    end
  end
end
