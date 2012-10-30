
require 'jellyfish'

Overheat = Class.new(RuntimeError)

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
    'return is ignored if body has already been set'
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

  class Matcher
    def match path
      path.reverse == 'match/'
    end
  end
  get Matcher.new do |match|
    "#{match}\n"
  end

  class Body
    def each
      if Object.const_defined?(:Rainbows)
        (0..4).each{ |i| yield "#{i}\n"; Rainbows.sleep(0.1) }
      else
        yield "You need Rainbows + FiberSpawn (or so) for this\n"
      end
    end
  end
  get '/chunked' do
    Body.new
  end

  get '/overheat' do
    raise Overheat
  end

  # get a hint that use `next' instead;
  get '/return' do; return; end
  get '/break'  do; break ; end
  get '/next'   do; next  ; end # this works
end

class Heater
  include Jellyfish
  handle Overheat do
    status 500
    "It's overheated\n"
  end

  get '/status' do
    temperature
  end

  get %r{^/sinatra/(?<id>\d+)$} do
    "#{params[:id]}\n"
  end

  def controller; Controller; end
  class Controller < Jellyfish::Controller
    include Jellyfish::Sinatra
    include Jellyfish::Newrelic
    def temperature
      "30\u{2103}\n"
    end
  end
end

HugeTank = Rack::Builder.new do
  use Rack::Chunked # order does matter, need to check Content-Length first
  use Rack::ContentLength
  use Rack::ContentType, 'text/plain'
  use Heater
  run Tank.new
end

run HugeTank

NewRelic::Agent.manual_start
NewRelic::Agent.shutdown
