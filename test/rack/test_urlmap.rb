
require 'jellyfish/test'
require 'jellyfish/urlmap'

require 'rack/mock'

describe Jellyfish::URLMap do
  would "dispatches paths correctly" do
    app = lambda { |env|
      [200, {
        'x-scriptname' => env['SCRIPT_NAME'],
        'x-pathinfo' => env['PATH_INFO'],
        'content-type' => 'text/plain'
      }, [""]]
    }
    map = Rack::Lint.new(Jellyfish::URLMap.new({
      'http://foo.org/bar' => app,
      '/foo' => app,
      '/foo/bar' => app
    }))

    res = Rack::MockRequest.new(map).get("/")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/qux")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/foo")
    res.should.ok?
    res["x-scriptname"].should.eq "/foo"
    res["x-pathinfo"].should.eq ""

    res = Rack::MockRequest.new(map).get("/foo/")
    res.should.ok?
    res["x-scriptname"].should.eq "/foo"
    res["x-pathinfo"].should.eq "/"

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.ok?
    res["x-scriptname"].should.eq "/foo/bar"
    res["x-pathinfo"].should.eq ""

    res = Rack::MockRequest.new(map).get("/foo/bar/")
    res.should.ok?
    res["x-scriptname"].should.eq "/foo/bar"
    res["x-pathinfo"].should.eq "/"

    res = Rack::MockRequest.new(map).get("/foo///bar//quux")
    res.status.should.eq 200
    res.should.ok?
    res["x-scriptname"].should.eq "/foo/bar"
    res["x-pathinfo"].should.eq "//quux"

    res = Rack::MockRequest.new(map).get("/foo/quux", "SCRIPT_NAME" => "/bleh")
    res.should.ok?
    res["x-scriptname"].should.eq "/bleh/foo"
    res["x-pathinfo"].should.eq "/quux"

    res = Rack::MockRequest.new(map).get("/bar", 'HTTP_HOST' => 'foo.org')
    res.should.ok?
    res["x-scriptname"].should.eq "/bar"
    res["x-pathinfo"].should.empty?

    res = Rack::MockRequest.new(map).get("/bar/", 'HTTP_HOST' => 'foo.org')
    res.should.ok?
    res["x-scriptname"].should.eq "/bar"
    res["x-pathinfo"].should.eq '/'
  end

  would "dispatches hosts correctly" do
    map = Rack::Lint.new(Jellyfish::URLMap.new("http://foo.org/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "foo.org",
                                "x-host" => env["HTTP_HOST"] || env["SERVER_NAME"],
                              }, [""]]},
                           "http://subdomain.foo.org/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "subdomain.foo.org",
                                "x-host" => env["HTTP_HOST"] || env["SERVER_NAME"],
                              }, [""]]},
                           "http://bar.org/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "bar.org",
                                "x-host" => env["HTTP_HOST"] || env["SERVER_NAME"],
                              }, [""]]},
                           "/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "default.org",
                                "x-host" => env["HTTP_HOST"] || env["SERVER_NAME"],
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/")
    res.should.ok?
    res["x-position"].should.eq "default.org"

    res = Rack::MockRequest.new(map).get("/", "HTTP_HOST" => "bar.org")
    res.should.ok?
    res["x-position"].should.eq "bar.org"

    res = Rack::MockRequest.new(map).get("/", "HTTP_HOST" => "foo.org")
    res.should.ok?
    res["x-position"].should.eq "foo.org"

    res = Rack::MockRequest.new(map).get("/", "HTTP_HOST" => "subdomain.foo.org", "SERVER_NAME" => "foo.org")
    res.should.ok?
    res["x-position"].should.eq "subdomain.foo.org"

    res = Rack::MockRequest.new(map).get("http://foo.org/")
    res.should.ok?
    res["x-position"].should.eq "foo.org"

    res = Rack::MockRequest.new(map).get("/", "HTTP_HOST" => "example.org")
    res.should.ok?
    res["x-position"].should.eq "default.org"

    res = Rack::MockRequest.new(map).get("/",
                                         "HTTP_HOST" => "example.org:9292",
                                         "SERVER_PORT" => "9292")
    res.should.ok?
    res["x-position"].should.eq "default.org"
  end

  would "be nestable" do
    map = Rack::Lint.new(Jellyfish::URLMap.new("/foo" =>
      Jellyfish::URLMap.new("/bar" =>
        Jellyfish::URLMap.new("/quux" =>  lambda { |env|
                           [200,
                            { "content-type" => "text/plain",
                              "x-position" => "/foo/bar/quux",
                              "x-pathinfo" => env["PATH_INFO"],
                              "x-scriptname" => env["SCRIPT_NAME"],
                            }, [""]]}
                         ))))

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/foo/bar/quux")
    res.should.ok?
    res["x-position"].should.eq "/foo/bar/quux"
    res["x-pathinfo"].should.eq ""
    res["x-scriptname"].should.eq "/foo/bar/quux"
  end

  would "route root apps correctly" do
    map = Rack::Lint.new(Jellyfish::URLMap.new("/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "root",
                                "x-pathinfo" => env["PATH_INFO"],
                                "x-scriptname" => env["SCRIPT_NAME"]
                              }, [""]]},
                           "/foo" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "foo",
                                "x-pathinfo" => env["PATH_INFO"],
                                "x-scriptname" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.ok?
    res["x-position"].should.eq "foo"
    res["x-pathinfo"].should.eq "/bar"
    res["x-scriptname"].should.eq "/foo"

    res = Rack::MockRequest.new(map).get("/foo")
    res.should.ok?
    res["x-position"].should.eq "foo"
    res["x-pathinfo"].should.eq ""
    res["x-scriptname"].should.eq "/foo"

    res = Rack::MockRequest.new(map).get("/bar")
    res.should.ok?
    res["x-position"].should.eq "root"
    res["x-pathinfo"].should.eq "/bar"
    res["x-scriptname"].should.eq ""

    res = Rack::MockRequest.new(map).get("")
    res.should.ok?
    res["x-position"].should.eq "root"
    res["x-pathinfo"].should.eq "/"
    res["x-scriptname"].should.eq ""
  end

  would "not squeeze slashes" do
    map = Rack::Lint.new(Jellyfish::URLMap.new("/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "root",
                                "x-pathinfo" => env["PATH_INFO"],
                                "x-scriptname" => env["SCRIPT_NAME"]
                              }, [""]]},
                           "/foo" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "foo",
                                "x-pathinfo" => env["PATH_INFO"],
                                "x-scriptname" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/http://example.org/bar")
    res.should.ok?
    res["x-position"].should.eq "root"
    res["x-pathinfo"].should.eq "/http://example.org/bar"
    res["x-scriptname"].should.eq ""
  end

  would "not be case sensitive with hosts" do
    map = Rack::Lint.new(Jellyfish::URLMap.new("http://example.org/" => lambda { |env|
                             [200,
                              { "content-type" => "text/plain",
                                "x-position" => "root",
                                "x-pathinfo" => env["PATH_INFO"],
                                "x-scriptname" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("http://example.org/")
    res.should.ok?
    res["x-position"].should.eq "root"
    res["x-pathinfo"].should.eq "/"
    res["x-scriptname"].should.eq ""

    res = Rack::MockRequest.new(map).get("http://EXAMPLE.ORG/")
    res.should.ok?
    res["x-position"].should.eq "root"
    res["x-pathinfo"].should.eq "/"
    res["x-scriptname"].should.eq ""
  end
end
