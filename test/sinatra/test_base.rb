
require 'jellyfish/test'

# stolen from sinatra
describe 'Sinatra base_test.rb' do
  paste :jellyfish

  would 'process requests with #call' do
    app = Class.new{
      include Jellyfish
      get '/' do
        'Hello World'
      end
    }.new
    app.respond_to?(:call).should.eq true
    status, _, body = get('/', app)
    status.should.eq 200
    body  .should.eq ['Hello World']
  end

  would 'not maintain state between requests' do
    app = Class.new{
      include Jellyfish
      get '/state' do
        @foo ||= 'new'
        body = "Foo: #{@foo}"
        @foo = 'discard'
        body
      end
    }.new

    2.times do
      status, _, body = get('/state', app)
      status.should.eq 200
      body  .should.eq ['Foo: new']
    end
  end

  describe 'Jellyfish as a Rack middleware' do
    inner_app ||= lambda{ |env|
      [210, {'x-downstream' => 'true'}, ['Hello from downstream']]
    }

    app = Class.new{
      include Jellyfish
      get '/' do
        'Hello from middleware'
      end

      get '/low-level-forward' do
        status, headers, body = jellyfish.app.call(env)
        self.status  status
        self.headers headers
        body
      end

      get '/explicit-forward' do
        headers_merge 'x-middleware' => 'true'
        status, headers, _ = jellyfish.app.call(env)
        self.status  status
        self.headers headers
        'Hello after explicit forward'
      end
    }.new(inner_app)

    would 'create a middleware that responds to #call with .new' do
      app.respond_to?(:call).should.eq true
    end

    would 'expose the downstream app' do
      app.app.object_id.should.eq inner_app.object_id
    end

    would 'intercept requests' do
      status, _, body = get('/', app)
      status.should.eq 200
      body  .should.eq ['Hello from middleware']
    end

    would 'forward requests downstream when no matching route found' do
      status, headers, body = get('/missing', app)
      status                 .should.eq 210
      headers['x-downstream'].should.eq 'true'
      body                   .should.eq ['Hello from downstream']
    end

    would 'call the downstream app directly and return result' do
      status, headers, body = get('/low-level-forward', app)
      status                 .should.eq 210
      headers['x-downstream'].should.eq 'true'
      body                   .should.eq ['Hello from downstream']
    end

    would 'forward the request and integrate the response' do
      status, headers, body =
        get('/explicit-forward', Rack::ContentLength.new(app))

      status                   .should.eq 210
      headers['x-downstream']  .should.eq 'true'
      headers['content-length'].should.eq '28'
      body.to_a                .should.eq ['Hello after explicit forward']
    end
  end
end
