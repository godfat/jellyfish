
require 'jellyfish/test'

# stolen from sinatra
describe 'Sinatra filter_test.rb' do
  behaves_like :jellyfish

  def new_app base=Object, &block
    Class.new(base){
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){ include Jellyfish::MultiActions }
      end
      instance_eval(&block)
    }.new
  end

  should 'executes filters in the order defined' do
    count = 0
    app = new_app{
      get     { count.should.eq 0; count = 1 }
      get     { count.should.eq 1; count = 2 }
      get('/'){ 'Hello World' }
    }

    status, _, body = get('/', app)
    status.should.eq 200
    count .should.eq 2
    body  .should.eq ['Hello World']
  end

  should 'modify env' do
    app = new_app{
      get{ env['BOO'] = 'MOO' }
      get('/foo'){ env['BOO'] }
    }

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['MOO']
  end

  should 'modify instance variables available to routes' do
    app = new_app{
      get{ @foo = 'bar' }
      get('/foo') { @foo }
    }

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['bar']
  end

  should 'allows redirects' do
    app = new_app{
      get{ found '/bar' }
      get('/foo') do
        fail 'before block should have halted processing'
        'ORLY?!'
      end
    }

    status, headers, body = get('/foo', app)
    status             .should.eq 302
    headers['Location'].should.eq '/bar'
    body.join          .should =~ %r{<h1>Jellyfish found: /bar</h1>}
  end

  should 'not modify the response with its return value' do
    app = new_app{
      get{ 'Hello World!' }
      get '/foo' do
        body.should.eq nil
        'cool'
      end
    }

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['cool']
  end

  should 'modify the response with halt' do
    app = new_app{
      get('/foo'){ throw :halt, [302, {}, ['Hi']] }
      get('/foo'){ 'should not happen' }
      get('/bar'){ status 402; body 'Ho'; throw :halt }
      get('/bar'){ 'should not happen' }
    }

    get('/foo', app).should.eq [302, {}, ['Hi']]
    get('/bar', app).should.eq [402, {}, ['Ho']]
  end

  should 'give you access to params' do
    app = new_app{
      get{ @foo = Rack::Request.new(env).params['foo'] }
      get('/foo'){ @foo.reverse }
    }

    status, _, body = get('/foo', app, 'foo=cool')
    status.should.eq 200
    body  .should.eq ['looc']
  end

  should 'run filters defined in superclasses' do
    par = new_app{ get{ @foo = 'hello from superclass' } }.class
    app = new_app(par){ get('/foo'){ @foo } }

    _, _, body = get('/foo', app)
    body.should.eq ['hello from superclass']

    par      .routes['get'].size.should.eq 1
    app.class.routes['get'].size.should.eq 2
  end
end
