
require 'jellyfish'

class Tank
  extend Jellyfish
  raise_exceptions false

  get '/' do
    "Jelly Kelly\n"
  end

  get %r{^/(?<id>\d+)$} do |match|
    "Jelly ##{match[:id]}\n"
  end

  post '/' do
    headers       'X-Jellyfish-Life' => '100'
    headers_merge 'X-Jellyfish-Mana' => '200'
    body "Jellyfish 100/200\n"
    status 201

    'ignored return in this case'
  end

  get '/env' do
    "#{env.inspect}\n"
  end

  get '/crash' do
    raise 'crash'
  end
end

use Rack::ContentLength
run Tank
