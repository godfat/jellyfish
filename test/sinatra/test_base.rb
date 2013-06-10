
require 'jellyfish/test'

# stolen from sinatra
describe 'Sinatra base_test.rb' do
  behaves_like :jellyfish

  should 'process requests with #call' do
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

  should 'not maintain state between requests' do
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
    behaves_like :jellyfish

    class TestMiddleware
      include Jellyfish
    end

    def inner_app
      @inner_app ||= lambda{ |env|
        [210, {'X-Downstream' => 'true'}, ['Hello from downstream']]
      }
    end

    def app
      @app ||= TestMiddleware.new(inner_app)
    end

    should 'create a middleware that responds to #call with .new' do
      app.respond_to?(:call).should.eq true
    end

    should 'expose the downstream app' do
      app.app.object_id.should.eq inner_app.object_id
    end

    class TestMiddleware
      get '/' do
        'Hello from middleware'
      end
    end

    should 'intercept requests' do
      status, _, body = get('/')
      status.should.eq 200
      body  .should.eq ['Hello from middleware']
    end

    should 'forward requests downstream when no matching route found' do
      status, headers, body = get('/missing')
      status                 .should.eq 210
      headers['X-Downstream'].should.eq 'true'
      body                   .should.eq ['Hello from downstream']
    end

    class TestMiddleware
      get '/low-level-forward' do
        status, headers, body = jellyfish.app.call(env)
        self.status  status
        self.headers headers
        body
      end
    end

    should 'call the downstream app directly and return result' do
      status, headers, body = get('/low-level-forward')
      status                 .should.eq 210
      headers['X-Downstream'].should.eq 'true'
      body                   .should.eq ['Hello from downstream']
    end

    class TestMiddleware
      get '/explicit-forward' do
        headers_merge 'X-Middleware' => 'true'
        status, headers, _ = jellyfish.app.call(env)
        self.status  status
        self.headers headers
        'Hello after explicit forward'
      end
    end

    should 'forward the request and integrate the response' do
      status, headers, body =
        get('/explicit-forward', Rack::ContentLength.new(app))

      status                   .should.eq 210
      headers['X-Downstream']  .should.eq 'true'
      headers['Content-Length'].should.eq '28'
      body                     .should.eq ['Hello after explicit forward']
    end
  end
end
