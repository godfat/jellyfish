
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
  behaves_like :jellyfish

  %w[get put post delete options patch head].each do |verb|
    should "define #{verb.upcase} request handlers with #{verb}" do
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

  should '404s when no route satisfies the request' do
    app = Class.new{
      include Jellyfish
      get('/foo'){}
    }.new
    status, _, _ = get('/bar', app)
    status.should.eq 404
  end

  should 'allows using unicode' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){ include Jellyfish::NormalizedPath }
      end
      get("/f\u{f6}\u{f6}"){}
    }.new
    status, _, _ = get('/f%C3%B6%C3%B6', app)
    status.should.eq 200
  end

  should 'handle encoded slashes correctly' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){ include Jellyfish::NormalizedPath }
      end
      get(%r{^/(.+)}){ |m| m[1] }
    }.new
    status, _, body = get('/foo%2Fbar', app)
    status.should.eq 200
    body  .should.eq ['foo/bar']
  end

  should 'override the content-type in error handlers' do
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

  should 'match empty PATH_INFO to "/" if no route is defined for ""' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){ include Jellyfish::NormalizedPath }
      end
      get '/' do
        'worked'
      end
    }.new

    status, headers, body = get('', app)
    status.should.eq 200
    body  .should.eq ['worked']
  end

  should 'exposes params with indifferent hash' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){include Jellyfish::NormalizedParams}
      end
      get %r{^/(?<foo>\w+)} do
        params['foo'].should.eq 'bar'
        params[:foo ].should.eq 'bar'
        'well, alright'
      end
    }.new

    _, _, body = get('/bar', app)
    body.should.eq ['well, alright']
  end

  should 'merges named params and query string params in params' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){include Jellyfish::NormalizedParams}
      end
      get %r{^/(?<foo>\w+)} do
        params['foo'].should.eq 'bar'
        params['baz'].should.eq 'biz'
      end
    }.new

    status, _, _ = get('/bar', app, 'QUERY_STRING' => 'baz=biz')
    status.should.eq 200
  end

  should 'support named captures like %r{/hello/(?<person>[^/?#]+)}' do
    app = Class.new{
      include Jellyfish
      get Regexp.new('/hello/(?<person>[^/?#]+)') do |m|
        "Hello #{m['person']}"
      end
    }.new

    _, _, body = get('/hello/Frank', app)
    body.should.eq ['Hello Frank']
  end

  should 'support optional named captures' do
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

  should 'not concatinate params with the same name' do
    app = Class.new{
      include Jellyfish
      def controller
        Class.new(Jellyfish::Controller){include Jellyfish::NormalizedParams}
      end
      get(%r{^/(?<foo>\w+)}){ |m| params[:foo] }
    }.new

    _, _, body = get('/a', app, 'QUERY_STRING' => 'foo=b')
    body.should.eq ['a']
  end
end
