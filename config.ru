
require 'jellyfish'

class Tank
  extend Jellyfish
  raise_exceptions false

  get '/' do
    "Jelly Kelly\n"
  end

  get %r{^/jelly/(?<id>\d+)$} do |match|
    "Jelly ##{match[:id]}\n"
  end

  get '/crash' do
    raise 'crash'
  end
end

use Rack::ContentLength
run Tank
