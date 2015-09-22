
require 'jellyfish/test'
require 'jellyfish/urlmap'

require 'rack/mock'

describe Jellyfish::URLMap do
  would "dispatches paths correctly" do
    app = lambda { |env|
      [200, {
        'X-ScriptName' => env['SCRIPT_NAME'],
        'X-PathInfo' => env['PATH_INFO'],
        'Content-Type' => 'text/plain'
      }, [""]]
    }
    map = Rack::Lint.new(Jellyfish::URLMap.new({
      '/bar' => app,
      '/foo' => app,
      '/foo/bar' => app
    }))

    res = Rack::MockRequest.new(map).get("/")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/qux")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/foo")
    res.should.ok?
    res["X-ScriptName"].should.eq "/foo"
    res["X-PathInfo"].should.eq ""

    res = Rack::MockRequest.new(map).get("/foo/")
    res.should.ok?
    res["X-ScriptName"].should.eq "/foo"
    res["X-PathInfo"].should.eq "/"

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.ok?
    res["X-ScriptName"].should.eq "/foo/bar"
    res["X-PathInfo"].should.eq ""

    res = Rack::MockRequest.new(map).get("/foo/bar/")
    res.should.ok?
    res["X-ScriptName"].should.eq "/foo/bar"
    res["X-PathInfo"].should.eq "/"

    res = Rack::MockRequest.new(map).get("/foo///bar//quux")
    res.status.should.eq 200
    res.should.ok?
    res["X-ScriptName"].should.eq "/foo/bar"
    res["X-PathInfo"].should.eq "//quux"

    res = Rack::MockRequest.new(map).get("/foo/quux", "SCRIPT_NAME" => "/bleh")
    res.should.ok?
    res["X-ScriptName"].should.eq "/bleh/foo"
    res["X-PathInfo"].should.eq "/quux"

    res = Rack::MockRequest.new(map).get("/bar", 'HTTP_HOST' => 'foo.org')
    res.should.ok?
    res["X-ScriptName"].should.eq "/bar"
    res["X-PathInfo"].should.empty?

    res = Rack::MockRequest.new(map).get("/bar/", 'HTTP_HOST' => 'foo.org')
    res.should.ok?
    res["X-ScriptName"].should.eq "/bar"
    res["X-PathInfo"].should.eq '/'
  end

  would "be nestable" do
    map = Rack::Lint.new(Rack::URLMap.new("/foo" =>
      Rack::URLMap.new("/bar" =>
        Rack::URLMap.new("/quux" =>  lambda { |env|
                           [200,
                            { "Content-Type" => "text/plain",
                              "X-Position" => "/foo/bar/quux",
                              "X-PathInfo" => env["PATH_INFO"],
                              "X-ScriptName" => env["SCRIPT_NAME"],
                            }, [""]]}
                         ))))

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.not_found?

    res = Rack::MockRequest.new(map).get("/foo/bar/quux")
    res.should.ok?
    res["X-Position"].should.eq "/foo/bar/quux"
    res["X-PathInfo"].should.eq ""
    res["X-ScriptName"].should.eq "/foo/bar/quux"
  end

  would "route root apps correctly" do
    map = Rack::Lint.new(Rack::URLMap.new("/" => lambda { |env|
                             [200,
                              { "Content-Type" => "text/plain",
                                "X-Position" => "root",
                                "X-PathInfo" => env["PATH_INFO"],
                                "X-ScriptName" => env["SCRIPT_NAME"]
                              }, [""]]},
                           "/foo" => lambda { |env|
                             [200,
                              { "Content-Type" => "text/plain",
                                "X-Position" => "foo",
                                "X-PathInfo" => env["PATH_INFO"],
                                "X-ScriptName" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/foo/bar")
    res.should.ok?
    res["X-Position"].should.eq "foo"
    res["X-PathInfo"].should.eq "/bar"
    res["X-ScriptName"].should.eq "/foo"

    res = Rack::MockRequest.new(map).get("/foo")
    res.should.ok?
    res["X-Position"].should.eq "foo"
    res["X-PathInfo"].should.eq ""
    res["X-ScriptName"].should.eq "/foo"

    res = Rack::MockRequest.new(map).get("/bar")
    res.should.ok?
    res["X-Position"].should.eq "root"
    res["X-PathInfo"].should.eq "/bar"
    res["X-ScriptName"].should.eq ""

    res = Rack::MockRequest.new(map).get("")
    res.should.ok?
    res["X-Position"].should.eq "root"
    res["X-PathInfo"].should.eq "/"
    res["X-ScriptName"].should.eq ""
  end

  would "not squeeze slashes" do
    map = Rack::Lint.new(Rack::URLMap.new("/" => lambda { |env|
                             [200,
                              { "Content-Type" => "text/plain",
                                "X-Position" => "root",
                                "X-PathInfo" => env["PATH_INFO"],
                                "X-ScriptName" => env["SCRIPT_NAME"]
                              }, [""]]},
                           "/foo" => lambda { |env|
                             [200,
                              { "Content-Type" => "text/plain",
                                "X-Position" => "foo",
                                "X-PathInfo" => env["PATH_INFO"],
                                "X-ScriptName" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/http://example.org/bar")
    res.should.ok?
    res["X-Position"].should.eq "root"
    res["X-PathInfo"].should.eq "/http://example.org/bar"
    res["X-ScriptName"].should.eq ""
  end

  would "not be case sensitive with hosts" do
    map = Rack::Lint.new(Rack::URLMap.new("/" => lambda { |env|
                             [200,
                              { "Content-Type" => "text/plain",
                                "X-Position" => "root",
                                "X-PathInfo" => env["PATH_INFO"],
                                "X-ScriptName" => env["SCRIPT_NAME"]
                              }, [""]]}
                           ))

    res = Rack::MockRequest.new(map).get("/")
    res.should.ok?
    res["X-Position"].should.eq "root"
    res["X-PathInfo"].should.eq "/"
    res["X-ScriptName"].should.eq ""

    res = Rack::MockRequest.new(map).get("/")
    res.should.ok?
    res["X-Position"].should.eq "root"
    res["X-PathInfo"].should.eq "/"
    res["X-ScriptName"].should.eq ""
  end
end
