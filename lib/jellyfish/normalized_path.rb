# frozen_string_literal: true

require 'jellyfish'
require 'uri'

module Jellyfish
  module NormalizedPath
    def path_info
      path = URI.decode_www_form_component(super, Encoding.default_external)
      if path.start_with?('/') then path else "/#{path}" end
    end
  end
end
