
require 'jellyfish'

class App
  extend Jellyfish
  get '/' do |match|
    "test\n"
  end

  get /(\d+)/ do |match|
    "#{match[1]}\n"
  end
end

use Rack::ContentLength
run App
