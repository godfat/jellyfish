
require 'jellyfish/test'

require 'rack/lint'
require 'rack/mock'
require 'rack/showexceptions'
require 'rack/urlmap'

describe Jellyfish::Builder do
  class NothingMiddleware
    def initialize(app)
      @app = app
    end
    def call(env)
      @@env = env
      response = @app.call(env)
      response
    end
    def self.env
      @@env
    end
  end

  def builder_to_app(&block)
    Rack::Lint.new Jellyfish::Builder.app(&block)
  end

  would "supports mapping" do
    app = builder_to_app do
      map '/' do |outer_env|
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['root']] }
      end
      map '/sub' do
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['sub']] }
      end
    end
    Rack::MockRequest.new(app).get("/").body.to_s.should.eq 'root'
    Rack::MockRequest.new(app).get("/sub").body.to_s.should.eq 'sub'
  end

  would "chains apps by default" do
    app = builder_to_app do
      use Rack::ShowExceptions
      run lambda { |env| raise "bzzzt" }
    end

    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
  end

  would "supports blocks on use" do
    app = builder_to_app do
      use Rack::ShowExceptions
      use Rack::Auth::Basic do |username, password|
        'secret' == password
      end

      run lambda { |env| [200, {"Content-Type" => "text/plain"}, ['Hi Boss']] }
    end

    response = Rack::MockRequest.new(app).get("/")
    response.should.client_error?
    response.status.should.eq 401

    # with auth...
    response = Rack::MockRequest.new(app).get("/",
        'HTTP_AUTHORIZATION' => 'Basic ' + ["joe:secret"].pack("m*"))
    response.status.should.eq 200
    response.body.to_s.should.eq 'Hi Boss'
  end

  would "has explicit #to_app" do
    app = builder_to_app do
      use Rack::ShowExceptions
      run lambda { |env| raise "bzzzt" }
    end

    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
  end

  would "can mix map and run for endpoints" do
    app = builder_to_app do
      map '/sub' do
        run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['sub']] }
      end
      run lambda { |inner_env| [200, {"Content-Type" => "text/plain"}, ['root']] }
    end

    Rack::MockRequest.new(app).get("/").body.to_s.should.eq 'root'
    Rack::MockRequest.new(app).get("/sub").body.to_s.should.eq 'sub'
  end

  would "accepts middleware-only map blocks" do
    app = builder_to_app do
      map('/foo') { use Rack::ShowExceptions }
      run lambda { |env| raise "bzzzt" }
    end

    proc { Rack::MockRequest.new(app).get("/") }.should.raise(RuntimeError)
    Rack::MockRequest.new(app).get("/foo").should.server_error?
  end

  would "yields the generated app to a block for warmup" do
    warmed_up_app = nil

    app = Rack::Builder.new do
      warmup { |a| warmed_up_app = a }
      run lambda { |env| [200, {}, []] }
    end.to_app

    warmed_up_app.should.eq app
  end

  would "initialize apps once" do
    app = builder_to_app do
      class AppClass
        def initialize
          @called = 0
        end
        def call(env)
          raise "bzzzt"  if @called > 0
        @called += 1
          [200, {'Content-Type' => 'text/plain'}, ['OK']]
        end
      end

      use Rack::ShowExceptions
      run AppClass.new
    end

    Rack::MockRequest.new(app).get("/").status.should.eq 200
    Rack::MockRequest.new(app).get("/").should.server_error?
  end

  would "allows use after run" do
    app = builder_to_app do
      run lambda { |env| raise "bzzzt" }
      use Rack::ShowExceptions
    end

    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
    Rack::MockRequest.new(app).get("/").should.server_error?
  end

  would 'complains about a missing run' do
    proc do
      Rack::Lint.new Rack::Builder.app { use Rack::ShowExceptions }
    end.should.raise(RuntimeError)
  end
end
