
require 'jellyfish'

class Tank
  include Jellyfish
  handle_exceptions false

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

  get '/lookup' do
    found "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
  end

  get '/crash' do
    raise 'crash'
  end

  handle NameError do |e|
    status 403
    "No one hears you: #{e.backtrace.first}\n"
  end

  get '/yell' do
    yell
  end
end

class Heater
  include Jellyfish
  get '/status' do
    "30\u{2103}\n"
  end
end

use Rack::ContentLength
use Heater
run Tank.new
