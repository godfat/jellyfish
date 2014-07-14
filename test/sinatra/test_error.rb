
require 'jellyfish/test'

describe 'Sinatra mapped_error_test.rb' do
  paste :jellyfish

  exp = Class.new(RuntimeError)

  would 'invoke handlers registered with handle when raised' do
    app = Class.new{
      include Jellyfish
      handle(exp){ 'Foo!' }
      get '/' do
        raise exp
      end
    }.new

    status, _, body = get('/', app)
    status.should.eq 200
    body  .should.eq ['Foo!']
  end

  would 'pass the exception object to the error handler' do
    app = Class.new{
      include Jellyfish
      handle(exp){ |e| e.should.kind_of?(exp) }
      get('/'){ raise exp }
    }.new
    get('/', app)
  end

  would 'use the StandardError handler if no matching handler found' do
    app = Class.new{
      include Jellyfish
      handle(StandardError){ 'StandardError!' }
      get('/'){ raise exp }
    }.new

    status, _, body = get('/', app)
    status.should.eq 200
    body  .should.eq ['StandardError!']
  end

  would 'favour subclass handler over superclass handler if available' do
    app = Class.new{
      include Jellyfish
      handle(StandardError){ 'StandardError!' }
      handle(RuntimeError) { 'RuntimeError!'  }
      get('/'){ raise exp }
    }.new

    status, _, body = get('/', app)
    status.should.eq 200
    body  .should.eq ['RuntimeError!']

    handlers = app.class.handlers
    handlers.size.should.eq 3
    handlers[exp].should.eq handlers[RuntimeError]
  end

  would 'pass the exception to the handler' do
    app = Class.new{
      include Jellyfish
      handle(exp){ |e|
        e.should.kind_of?(exp)
        'looks good'
      }
      get('/'){ raise exp }
    }.new

    _, _, body = get('/', app)
    body.should.eq ['looks good']
  end

  would 'raise errors from the app when handle_exceptions is false' do
    app = Class.new{
      include Jellyfish
      handle_exceptions false
      get('/'){ raise exp }
    }.new

    lambda{ get('/', app) }.should.raise(exp)
  end

  would 'call error handlers even when handle_exceptions is false' do
    app = Class.new{
      include Jellyfish
      handle_exceptions false
      handle(exp){ "she's there." }
      get('/'){ raise exp }
    }.new

    _, _, body = get('/', app)
    body.should.eq ["she's there."]
  end

  would 'catch Jellyfish::NotFound' do
    app = Class.new{
      include Jellyfish
      get('/'){ not_found }
    }.new

    status, _, _ = get('/', app)
    status.should.eq 404
  end

  would 'handle subclasses of Jellyfish::NotFound' do
    e   = Class.new(Jellyfish::NotFound)
    app = Class.new{
      include Jellyfish
      get('/'){ halt e.new }
    }.new

    status, _, _ = get('/', app)
    status.should.eq 404
  end

  would 'no longer cascade with Jellyfish::NotFound' do
    app = Class.new{
      include Jellyfish
      get('/'){ not_found }
    }.new(Class.new{
      include Jellyfish
      get('/'){ 'never'.should.eq 'reach' }
    })

    status, _, _ = get('/', app)
    status.should.eq 404
  end

  would 'cascade with Jellyfish::Cascade' do
    app = Class.new{
      include Jellyfish
      get('/'){ cascade }
    }.new(Class.new{
      include Jellyfish
      get('/'){ 'reach' }
    }.new)

    status, _, body = get('/', app)
    status.should.eq 200
    body  .should.eq ['reach']
  end

  would 'inherit error mappings from base class' do
    sup = Class.new{
      include Jellyfish
      handle(exp){ 'sup' }
    }
    app = Class.new(sup){
      get('/'){ raise exp }
    }.new

    _, _, body = get('/', app)
    body.should.eq ['sup']
  end

  would 'override error mappings in base class' do
    sup = Class.new{
      include Jellyfish
      handle(exp){ 'sup' }
    }
    app = Class.new(sup){
      handle(exp){ 'sub' }
      get('/'){ raise exp }
    }.new

    _, _, body = get('/', app)
    body.should.eq ['sub']
  end
end
