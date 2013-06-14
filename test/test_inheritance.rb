
require 'jellyfish/test'

describe 'Inheritance' do
  behaves_like :jellyfish

  should 'inherit routes' do
    sup = Class.new{
      include Jellyfish
      get('/0'){ 'a' }
    }
    app = Class.new(sup){
      get('/1'){ 'b' }
    }.new

    [['/0', 'a'], ['/1', 'b']].each do |(path, expect)|
      _, _, body = get(path, app)
      body.should.eq [expect]
    end

    _, _, body = get('/0', sup.new)
    body.should.eq ['a']
    status, _, _ = get('/1', sup.new)
    status.should.eq 404

    sup      .routes['get'].size.should.eq 1
    app.class.routes['get'].size.should.eq 2
  end

  should 'inherit handlers' do
    sup = Class.new{
      include Jellyfish
      handle(TypeError){ 'a' }
      get('/type') { raise TypeError     }
      get('/argue'){ raise ArgumentError }
    }
    app = Class.new(sup){
      handle(ArgumentError){ 'b' }
    }.new

    [['/type', 'a'], ['/argue', 'b']].each do |(path, expect)|
      _, _, body = get(path, app)
      body.should.eq [expect]
    end

    sup      .handlers.size.should.eq 1
    app.class.handlers.size.should.eq 2
  end

  should 'inherit controller' do
    sup = Class.new{
      include Jellyfish
      controller_include Module.new{ def f; 'a'; end }
      get('/0'){ f }
    }
    app = Class.new(sup){
      get('/1'){ f }
    }.new

    [['/0', 'a'], ['/1', 'a']].each do |(path, expect)|
      _, _, body = get(path, app)
      body.should.eq [expect]
    end

    sup      .controller_include.size.should.eq 1
    app.class.controller_include.size.should.eq 1
  end

  should 'inherit handle_exceptions' do
    sup = Class.new{
      include Jellyfish
      handle_exceptions false
    }
    app = Class.new(sup)

    sup.handle_exceptions.should.eq false
    app.handle_exceptions.should.eq false

    sup.handle_exceptions true
    sup.handle_exceptions.should.eq true
    app.handle_exceptions.should.eq false

    sup.handle_exceptions false
    app.handle_exceptions true
    sup.handle_exceptions.should.eq false
    app.handle_exceptions.should.eq true
  end
end
