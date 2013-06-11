
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

    status, _, body = get('/foo', app, 'QUERY_STRING' => 'foo=cool')
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

  should 'take an optional route pattern' do
    ran_filter = false
    app = new_app{
      get(%r{^/b}){ ran_filter = true }
      get('/foo') {}
      get('/bar') {}
    }
    get('/foo', app)
    ran_filter.should.eq false
    get('/bar', app)
    ran_filter.should.eq true
  end

  should 'generate block arguments from route pattern' do
    subpath = nil
    app = new_app{
      get(%r{^/foo/(\w+)}){ |m| subpath = m[1] }
    }
    get('/foo/bar', app)
    subpath.should.eq 'bar'
  end

  should 'execute before and after filters in correct order' do
    invoked = 0
    app = new_app{
      get     { invoked  = 2 }
      get('/'){ invoked += 2; body 'hello' }
      get     { invoked *= 2 }
    }

    status, _, body = get('/', app)
    status .should.eq 200
    body   .should.eq ['hello']
    invoked.should.eq 8
  end

  should 'execute filters in the order defined' do
    count = 0
    app = new_app{
      get('/'){ body 'Hello World' }
      get{
        count.should.eq 0
        count = 1
      }
      get{
        count.should.eq 1
        count = 2
      }
    }

    status, _, body = get('/', app)
    status.should.eq 200
    count .should.eq 2
    body  .should.eq ['Hello World']
  end

  should 'allow redirects' do
    app = new_app{
      get('/foo'){ 'ORLY' }
      get        { found '/bar' }
    }

    status, headers, body = get('/foo', app)
    status             .should.eq 302
    headers['Location'].should.eq '/bar'
    body.join          .should =~ %r{<h1>Jellyfish found: /bar</h1>}
  end

  should 'not modify the response with its return value' do
    app = new_app{
      get('/foo'){ body 'cool' }
      get        { 'Hello World!' }
    }

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['cool']
  end

  should 'modify the response with halt' do
    app = new_app{
      get('/foo'){ 'should not be returned' }
      get{ throw :halt, [302, {}, ['Hi']] }
    }

    status, _, body = get('/foo', app)
    status.should.eq 302
    body  .should.eq ['Hi']
  end

  should 'take an optional route pattern' do
    ran_filter = false
    app = new_app{
      get('/foo') {}
      get('/bar') {}
      get(%r{^/b}){ ran_filter = true }
    }
    get('/foo', app)
    ran_filter.should.eq false
    get('/bar', app)
    ran_filter.should.eq true
  end
end
