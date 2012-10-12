
require 'jellyfish'

class Tank
  extend Jellyfish
  raise_exceptions false

  get '/' do |match|
    "Jelly Kelly\n"
  end

  get /(\d+)/ do |match|
    "Jelly ##{match[1]}\n"
  end
end

use Rack::ContentLength
run Tank
