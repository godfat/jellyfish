
require 'jellyfish/test'

class RegexpLookAlike
  class MatchData
    def captures
      ["this", "is", "a", "test"]
    end
  end

  def match(string)
    ::RegexpLookAlike::MatchData.new if string == "/this/is/a/test/"
  end

  def keys
    ["one", "two", "three", "four"]
  end
end

# stolen from sinatra
describe 'Sinatra routing_test.rb' do
  paste :jellyfish

  %w[get put post delete options patch head].each do |verb|
    would "define #{verb.upcase} request handlers with #{verb}" do
      app = Class.new{
        include Jellyfish
        send verb, '/hello' do
          'Hello World'
        end
      }.new

      status, _, body = send(verb, '/hello', app)
      status.should.eq 200
      body  .should.eq ['Hello World']
    end
  end

  would '404s when no route satisfies the request' do
    app = Class.new{
      include Jellyfish
      get('/foo'){}
    }.new
    status, _, _ = get('/bar', app)
    status.should.eq 404
  end

  would 'allows using unicode' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedPath
      get("/f\u{f6}\u{f6}"){}
    }.new
    status, _, _ = get('/f%C3%B6%C3%B6', app)
    status.should.eq 200
  end

  would 'handle encoded slashes correctly' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedPath
      get(%r{^/(.+)}){ |m| m[1] }
    }.new
    status, _, body = get('/foo%2Fbar', app)
    status.should.eq 200
    body  .should.eq ['foo/bar']
  end

  would 'override the content-type in error handlers' do
    app = Class.new{
      include Jellyfish
      get{
        self.headers 'Content-Type' => 'text/plain'
        status, headers, body = jellyfish.app.call(env)
        self.status  status
        self.body    body
        headers_merge(headers)
      }
    }.new(Class.new{
      include Jellyfish
      handle Jellyfish::NotFound do
        headers_merge 'Content-Type' => 'text/html'
        status 404
        '<h1>Not Found</h1>'
      end
    }.new)

    status, headers, body = get('/foo', app)
    status                 .should.eq 404
    headers['Content-Type'].should.eq 'text/html'
    body                   .should.eq ['<h1>Not Found</h1>']
  end

  would 'match empty PATH_INFO to "/" if no route is defined for ""' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedPath
      get('/'){ 'worked' }
    }.new

    status, _, body = get('', app)
    status.should.eq 200
    body  .should.eq ['worked']
  end

  would 'exposes params with indifferent hash' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedParams

      get %r{^/(?<foo>\w+)} do
        params['foo'].should.eq 'bar'
        params[:foo ].should.eq 'bar'
        'well, alright'
      end
    }.new

    _, _, body = get('/bar', app)
    body.should.eq ['well, alright']
  end

  would 'merges named params and query string params in params' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedParams

      get %r{^/(?<foo>\w+)} do
        params['foo'].should.eq 'bar'
        params['baz'].should.eq 'biz'
      end
    }.new

    status, _, _ = get('/bar', app, 'QUERY_STRING' => 'baz=biz')
    status.should.eq 200
  end

  would 'support named captures like %r{/hello/(?<person>[^/?#]+)}' do
    app = Class.new{
      include Jellyfish
      get Regexp.new('/hello/(?<person>[^/?#]+)') do |m|
        "Hello #{m['person']}"
      end
    }.new

    _, _, body = get('/hello/Frank', app)
    body.should.eq ['Hello Frank']
  end

  would 'support optional named captures' do
    app = Class.new{
      include Jellyfish
      get Regexp.new('/page(?<format>.[^/?#]+)?') do |m|
        "format=#{m[:format]}"
      end
    }.new

    status, _, body = get('/page.html', app)
    status.should.eq 200
    body  .should.eq ['format=.html']

    status, _, body = get('/page.xml', app)
    status.should.eq 200
    body  .should.eq ['format=.xml']

    status, _, body = get('/page', app)
    status.should.eq 200
    body  .should.eq ['format=']
  end

  would 'not concatinate params with the same name' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedParams

      get(%r{^/(?<foo>\w+)}){ |m| params[:foo] }
    }.new

    _, _, body = get('/a', app, 'QUERY_STRING' => 'foo=b')
    body.should.eq ['a']
  end

  would 'support basic nested params' do
    app = Class.new{
      include Jellyfish
      get('/hi'){ request.params['person']['name'] }
    }.new

    status, _, body = get('/hi', app,
                          'QUERY_STRING' => 'person[name]=John+Doe')
    status.should.eq 200
    body.should.eq ['John Doe']
  end

  would "expose nested params with indifferent hash" do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedParams

      get '/testme' do
        params['bar']['foo'].should.eq 'baz'
        params['bar'][:foo ].should.eq 'baz'
        'well, alright'
      end
    }.new

    _, _, body = get('/testme', app, 'QUERY_STRING' => 'bar[foo]=baz')
    body.should.eq ['well, alright']
  end

  would 'preserve non-nested params' do
    app = Class.new{
      include Jellyfish
      get '/foo' do
        request.params['article_id']     .should.eq '2'
        request.params['comment']['body'].should.eq 'awesome'
        request.params['comment[body]']  .should.eq nil
        'looks good'
      end
    }.new

    status, _, body = get('/foo', app,
      'QUERY_STRING' => 'article_id=2&comment[body]=awesome')
    status.should.eq 200
    body  .should.eq ['looks good']
  end

  would 'match paths that include spaces encoded with %20' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedPath
      get('/path with spaces'){ 'looks good' }
    }.new

    status, _, body = get('/path%20with%20spaces', app)
    status.should.eq 200
    body  .should.eq ['looks good']
  end

  would 'match paths that include spaces encoded with +' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedPath
      get('/path with spaces'){ 'looks good' }
    }.new

    status, _, body = get('/path+with+spaces', app)
    status.should.eq 200
    body  .should.eq ['looks good']
  end

  would 'make regular expression captures available' do
    app = Class.new{
      include Jellyfish
      get(/^\/fo(.*)\/ba(.*)/) do |m|
        m[1..-1].should.eq ['orooomma', 'f']
        'right on'
      end
    }.new

    status, _, body = get('/foorooomma/baf', app)
    status.should.eq 200
    body  .should.eq ['right on']
  end

  would 'support regular expression look-alike routes' do
    app = Class.new{
      include Jellyfish
      controller_include Jellyfish::NormalizedParams
      matcher = Object.new
      def matcher.match path
        %r{/(?<one>\w+)/(?<two>\w+)/(?<three>\w+)/(?<four>\w+)}.match(path)
      end

      get(matcher) do |m|
        [m, params].each do |q|
          q[:one]  .should.eq 'this'
          q[:two]  .should.eq 'is'
          q[:three].should.eq 'a'
          q[:four] .should.eq 'test'
        end
        'right on'
      end
    }.new

    status, _, body = get('/this/is/a/test/', app)
    status.should.eq 200
    body  .should.eq ['right on']
  end

  would 'raise a TypeError when pattern is not a String or Regexp' do
    lambda{ Class.new{ include Jellyfish; get(42){} } }.
      should.raise(TypeError)
  end

  would 'match routes defined in superclasses' do
    sup = Class.new{
      include Jellyfish
      get('/foo'){ 'foo' }
    }
    app = Class.new(sup){
      get('/bar'){ 'bar' }
    }.new

    %w[foo bar].each do |path|
      status, _, body = get("/#{path}", app)
      status.should.eq 200
      body  .should.eq [path]
    end
  end

  would 'match routes itself first then downward app' do
    sup = Class.new{
      include Jellyfish
      get('/foo'){ 'foo sup' }
      get('/bar'){ 'bar sup' }
    }
    app = Class.new{
      include Jellyfish
      get('/foo'){ 'foo sub' }
    }.new(sup.new)

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['foo sub']

    status, _, body = get('/bar', app)
    status.should.eq 200
    body  .should.eq ['bar sup']
  end

  would 'allow using call to fire another request internally' do
    app = Class.new{
      include Jellyfish
      get '/foo' do
        status, headers, body = call(env.merge('PATH_INFO' => '/bar'))
        self.status  status
        self.headers headers
        self.body    body.map(&:upcase)
      end

      get '/bar' do
        'bar'
      end
    }.new

    status, _, body = get('/foo', app)
    status.should.eq 200
    body  .should.eq ['BAR']
  end

  would 'play well with other routing middleware' do
    middleware = Class.new{include Jellyfish}
    inner_app  = Class.new{include Jellyfish; get('/foo'){ 'hello' } }
    app = Rack::Builder.app do
      use middleware
      map('/test'){ run inner_app.new }
    end

    status, _, body = get('/test/foo', app)
    status.should.eq 200
    body  .should.eq ['hello']
  end
end
