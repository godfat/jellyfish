# Jellyfish [![Pipeline status](https://gitlab.com/godfat/jellyfish/badges/master/pipeline.svg)](https://gitlab.com/godfat/jellyfish/-/pipelines)

by Lin Jen-Shin ([godfat](http://godfat.org))

![logo](https://github.com/godfat/jellyfish/raw/master/jellyfish.png)

## LINKS:

* [github](https://github.com/godfat/jellyfish)
* [rubygems](https://rubygems.org/gems/jellyfish)
* [rdoc](http://rdoc.info/github/godfat/jellyfish)
* [issues](https://github.com/godfat/jellyfish/issues) (feel free to ask for support)

## DESCRIPTION:

Pico web framework for building API-centric web applications.
For Rack applications or Rack middleware. Around 250 lines of code.

Check [jellyfish-contrib][] for extra extensions.

[jellyfish-contrib]: https://github.com/godfat/jellyfish-contrib

## DESIGN:

* Learn the HTTP way instead of using some pointless helpers.
* Learn the Rack way instead of wrapping around Rack functionalities.
* Learn regular expression for routes instead of custom syntax.
* Embrace simplicity over convenience.
* Don't make things complicated only for _some_ convenience, but for
  _great_ convenience, or simply stay simple for simplicity.
* More features are added as extensions.
* Consider use [rack-protection][] if you're not only building an API server.
* Consider use [websocket_parser][] if you're trying to use WebSocket.
  Please check example below.

[rack-protection]: https://github.com/rkh/rack-protection
[websocket_parser]: https://github.com/afcapel/websocket_parser

## FEATURES:

* Minimal
* Simple
* Modular
* No templates (You could use [tilt](https://github.com/rtomayko/tilt))
* No ORM (You could use [sequel](http://sequel.jeremyevans.net/))
* No `dup` in `call`
* Regular expression routes, e.g. `get %r{^/(?<id>\d+)$}`
* String routes, e.g. `get '/'`
* Custom routes, e.g. `get Matcher.new`
* Build for either Rack applications or Rack middleware
* Include extensions for more features (checkout [jellyfish-contrib][])

## WHY?

Because Sinatra is too complex and inconsistent for me.

## REQUIREMENTS:

* Tested with MRI (official CRuby) and JRuby.

## INSTALLATION:

    gem install jellyfish

## SYNOPSIS:

You could also take a look at [config.ru](config.ru) as an example.

### Hello Jellyfish, your lovely config.ru

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get '/' do
    "Jelly Kelly\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /
[200,
 {'Content-Length' => '12', 'Content-Type' => 'text/plain'},
 ["Jelly Kelly\n"]]
-->

### Regular expression routes

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get %r{^/(?<id>\d+)$} do |match|
    "Jelly ##{match[:id]}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /123
[200,
 {'Content-Length' => '11', 'Content-Type' => 'text/plain'},
 ["Jelly #123\n"]]
-->

### Custom matcher routes

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  class Matcher
    def match path
      path.reverse == 'match/'
    end
  end
  get Matcher.new do |match|
    "#{match}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /hctam
[200,
 {'Content-Length' => '5', 'Content-Type' => 'text/plain'},
 ["true\n"]]
-->

### Different HTTP status and custom headers

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  post '/' do
    headers       'X-Jellyfish-Life' => '100'
    headers_merge 'X-Jellyfish-Mana' => '200'
    body "Jellyfish 100/200\n"
    status 201
    'return is ignored if body has already been set'
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
POST /
[201,
 {'Content-Length' => '18', 'Content-Type' => 'text/plain',
  'X-Jellyfish-Life' => '100', 'X-Jellyfish-Mana' => '200'},
 ["Jellyfish 100/200\n"]]
-->

### Redirect helper

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get '/lookup' do
    found "#{env['rack.url_scheme']}://#{env['HTTP_HOST']}/"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /lookup host
body = File.read("#{File.dirname(
  File.expand_path(__FILE__))}/../lib/jellyfish/public/302.html").
  gsub('VAR_URL', 'http://host/')
[302,
 {'Content-Length' => body.bytesize.to_s, 'Content-Type' => 'text/html',
  'Location' => 'http://host/'},
 [body]]
-->

### Crash-proof

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get '/crash' do
    raise 'crash'
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /crash
body = File.read("#{File.dirname(
  File.expand_path(__FILE__))}/../lib/jellyfish/public/500.html")
[500,
 {'Content-Length' => body.bytesize.to_s, 'Content-Type' => 'text/html'},
 [body]]
-->

### Custom error handler

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  handle NameError do |e|
    status 403
    "No one hears you: #{e.backtrace.first}\n"
  end
  get '/yell' do
    yell
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /yell
body = case RUBY_ENGINE
       when 'jruby'
         "No one hears you: (eval):9:in `block in Tank'\n"
       when 'rbx'
         "No one hears you: core/zed.rb:1370:in `yell (method_missing)'\n"
       else
         "No one hears you: (eval):9:in `block in <class:Tank>'\n"
       end
[403,
 {'Content-Length' => body.bytesize.to_s, 'Content-Type' => 'text/plain'},
 [body]]
-->

### Custom error 404 handler

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  handle Jellyfish::NotFound do |e|
    status 404
    "You found nothing."
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /
[404,
 {'Content-Length' => '18', 'Content-Type' => 'text/plain'},
 ["You found nothing."]]
-->

### Custom error handler for multiple errors

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  handle Jellyfish::NotFound, NameError do |e|
    status 404
    "You found nothing."
  end
  get '/yell' do
    yell
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /
[404,
 {'Content-Length' => '18', 'Content-Type' => 'text/plain'},
 ["You found nothing."]]
-->

### Access Rack::Request and params

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get '/report' do
    "Your name is #{request.params['name']}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /report?name=godfat
[200,
 {'Content-Length' => '20', 'Content-Type' => 'text/plain'},
 ["Your name is godfat\n"]]
-->

### Re-dispatch the request with modified env

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  get '/report' do
    status, headers, body = jellyfish.call(env.merge('PATH_INFO' => '/info'))
    self.status  status
    self.headers headers
    self.body    body
  end
  get('/info'){ "OK\n" }
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /report
[200,
 {'Content-Length' => '3', 'Content-Type' => 'text/plain'},
 ["OK\n"]]
-->

### Include custom helper in built-in controller

Basically it's the same as defining a custom controller and then
include the helper. This is merely a short hand. See next section
for defining a custom controller.

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    temperature
  end

  module Helper
    def temperature
      "30\u{2103}\n"
    end
  end
  controller_include Helper
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Heater.new
```

<!---
GET /status
[200,
 {'Content-Length' => '6', 'Content-Type' => 'text/plain'},
 ["30\u{2103}\n"]]
-->

### Define custom controller manually

This is effectively the same as defining a helper module as above and
include it, but more flexible and extensible.

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    temperature
  end

  class Controller < Jellyfish::Controller
    def temperature
      "30\u{2103}\n"
    end
  end
  controller Controller
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Heater.new
```

<!---
GET /status
[200,
 {'Content-Length' => '6', 'Content-Type' => 'text/plain'},
 ["30\u{2103}\n"]]
-->

### Override dispatch for processing before action

We don't have before action built-in, but we could override `dispatch` in
the controller to do the same thing. CAVEAT: Remember to call `super`.

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Module.new{
    def dispatch
      @state = 'jumps'
      super
    end
  }

  get do
    "Jelly #{@state}.\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /123
[200,
 {'Content-Length' => '13', 'Content-Type' => 'text/plain'},
 ["Jelly jumps.\n"]]
-->

### Extension: Jellyfish::Builder, a faster Rack::Builder and Rack::URLMap

Default `Rack::Builder` and `Rack::URLMap` is routing via linear search,
which could be very slow with a large number of routes. We could use
`Jellyfish::Builder` in this case because it would compile the routes
into a regular expression, it would be matching much faster than
linear search.

Note that `Jellyfish::Builder` is not a complete compatible implementation.
The followings are intentional:

* There's no `Jellyfish::Builder.call` because it doesn't make sense in my
  opinion. Always use `Jellyfish::Builder.app` instead.

* There's no `Jellyfish::Builder.parse_file` and
  `Jellyfish::Builder.new_from_string` because Rack servers are not
  going to use `Jellyfish::Builder` to parse `config.ru` at this point.
  We could provide this if there's a need.

* `Jellyfish::URLMap` does not modify `env`, and it would call the app with
  another instance of Hash. Mutating data is a bad idea.

* All other tests passed the same test suites for `Rack::Builder` and
  `Jellyfish::URLMap`.

``` ruby
require 'jellyfish'

run Jellyfish::Builder.app{
  map '/a'   do; run lambda{ |_| [200, {}, ["a\n"]  ] }; end
  map '/b'   do; run lambda{ |_| [200, {}, ["b\n"]  ] }; end
  map '/c'   do; run lambda{ |_| [200, {}, ["c\n"]  ] }; end
  map '/d'   do; run lambda{ |_| [200, {}, ["d\n"]  ] }; end
  map '/e' do
    map '/f' do; run lambda{ |_| [200, {}, ["e/f\n"]] }; end
    map '/g' do; run lambda{ |_| [200, {}, ["e/g\n"]] }; end
    map '/h' do; run lambda{ |_| [200, {}, ["e/h\n"]] }; end
    map '/i' do; run lambda{ |_| [200, {}, ["e/i\n"]] }; end
    map '/'  do; run lambda{ |_| [200, {}, ["e\n"]]   }; end
  end
  map '/j'   do; run lambda{ |_| [200, {}, ["j\n"]  ] }; end
  map '/k'   do; run lambda{ |_| [200, {}, ["k\n"]  ] }; end
  map '/l'   do; run lambda{ |_| [200, {}, ["l\n"]  ] }; end
  map '/m' do
    map '/g' do; run lambda{ |_| [200, {}, ["m/g\n"]] }; end
    run lambda{ |_| [200, {}, ["m\n"]  ] }
  end

  use Rack::ContentLength
  run lambda{ |_| [200, {}, ["/\n"]] }
}
```

<!---
GET /a
[200, {}, ["a\n"]]

GET /a/x
[200, {}, ["a\n"]]

GET /b
[200, {}, ["b\n"]]

GET /c
[200, {}, ["c\n"]]

GET /d
[200, {}, ["d\n"]]

GET /e/f
[200, {}, ["e/f\n"]]

GET /e/g
[200, {}, ["e/g\n"]]

GET /e/h
[200, {}, ["e/h\n"]]

GET /e/i
[200, {}, ["e/i\n"]]

GET /e/
[200, {}, ["e\n"]]

GET /e
[200, {}, ["e\n"]]

GET /e/x
[200, {}, ["e\n"]]

GET /j
[200, {}, ["j\n"]]

GET /k
[200, {}, ["k\n"]]

GET /l
[200, {}, ["l\n"]]

GET /m/g
[200, {}, ["m/g\n"]]

GET /m
[200, {}, ["m\n"]]

GET /m/
[200, {}, ["m\n"]]

GET /m/x
[200, {}, ["m\n"]]

GET /
[200, {'Content-Length' => '2'}, ["/\n"]]

GET /x
[200, {'Content-Length' => '2'}, ["/\n"]]

GET /ab
[200, {'Content-Length' => '2'}, ["/\n"]]
-->

You could try a stupid benchmark yourself:

    ruby -Ilib bench/bench_builder.rb

For a 1000 routes app, here's my result:

```
Calculating -------------------------------------
   Jellyfish::URLMap     5.726k i/100ms
        Rack::URLMap   167.000  i/100ms
-------------------------------------------------
   Jellyfish::URLMap     62.397k (± 1.2%) i/s -    314.930k
        Rack::URLMap      1.702k (± 1.5%) i/s -      8.517k

Comparison:
   Jellyfish::URLMap:    62397.3 i/s
        Rack::URLMap:     1702.0 i/s - 36.66x slower
```

#### Extension: Jellyfish::Builder#listen

`listen` is a convenient way to define routing based on the host. We could
also use `map` inside `listen` block. Here's a quick example that specifically
listen on a particular host for long-polling and all other hosts would go to
the default app.

``` ruby
require 'jellyfish'

long_poll = lambda{ |env| [200, {}, ["long_poll #{env['HTTP_HOST']}\n"]] }
fast_app  = lambda{ |env| [200, {}, ["fast_app  #{env['HTTP_HOST']}\n"]] }

run Jellyfish::Builder.app{
  listen 'slow-app' do
    run long_poll
  end

  run fast_app
}
```

<!---
GET / slow-app
[200, {}, ["long_poll slow-app\n"]]

GET / fast-app
[200, {}, ["fast_app  fast-app\n"]]
-->

##### Extension: Jellyfish::Builder#listen (`map path, host:`)

Alternatively, we could pass `host` as an argument to `map` so that the
endpoint would only listen on a specific host.

``` ruby
require 'jellyfish'

long_poll = lambda{ |env| [200, {}, ["long_poll #{env['HTTP_HOST']}\n"]] }
fast_app  = lambda{ |env| [200, {}, ["fast_app  #{env['HTTP_HOST']}\n"]] }

run Jellyfish::Builder.app{
  map '/', host: 'slow-app' do
    run long_poll
  end

  run fast_app
}
```

<!---
GET / slow-app
[200, {}, ["long_poll slow-app\n"]]

GET / fast-app
[200, {}, ["fast_app  fast-app\n"]]
-->

<!---
GET / slow-app
[200, {}, ["long_poll slow-app\n"]]

GET / fast-app
[200, {}, ["fast_app  fast-app\n"]]
-->

##### Extension: Jellyfish::Builder#listen (`map "http://#{path}"`)

Or if you really prefer the `Rack::URLMap` compatible way, then you could
just add `http://host` to your path prefix. `https` works, too.

``` ruby
require 'jellyfish'

long_poll = lambda{ |env| [200, {}, ["long_poll #{env['HTTP_HOST']}\n"]] }
fast_app  = lambda{ |env| [200, {}, ["fast_app  #{env['HTTP_HOST']}\n"]] }

run Jellyfish::Builder.app{
  map 'http://slow-app' do
    run long_poll
  end

  run fast_app
}
```

<!---
GET / slow-app
[200, {}, ["long_poll slow-app\n"]]

GET / fast-app
[200, {}, ["fast_app  fast-app\n"]]
-->

#### Extension: Jellyfish::Rewrite

`Jellyfish::Builder` is mostly compatible with `Rack::Builder`, and
`Jellyfish::Rewrite` is an extension to `Rack::Builder` which allows
you to rewrite `env['PATH_INFO']` in an easy way. In an ideal world,
we don't really need this. But in real world, we might want to have some
backward compatible API which continues to work even if the API endpoint
has already been changed.

Suppose the old API was: `/users/me`, and we want to change to `/profiles/me`,
while leaving the `/users/list` as before. We may have this:

``` ruby
require 'jellyfish'

users_api    = lambda{ |env| [200, {}, ["/users#{env['PATH_INFO']}\n"]] }
profiles_api = lambda{ |env| [200, {}, ["/profiles#{env['PATH_INFO']}\n"]] }

run Jellyfish::Builder.app{
  rewrite '/users/me' => '/me' do
    run profiles_api
  end
  map '/profiles' do
    run profiles_api
  end
  map '/users' do
    run users_api
  end
}
```

<!---
GET /users/me
[200, {}, ["/profiles/me\n"]]

GET /users/list
[200, {}, ["/users/list\n"]]

GET /profiles/me
[200, {}, ["/profiles/me\n"]]

GET /profiles/list
[200, {}, ["/profiles/list\n"]]
-->

This way, we would rewrite `/users/me` to `/profiles/me` and serve it with
our profiles API app, while leaving all other paths begin with `/users`
continue to work with the old users API app.

##### Extension: Jellyfish::Rewrite (`map path, to:`)

Note that you could also use `map path, :to` if you prefer this API more:

``` ruby
require 'jellyfish'

users_api    = lambda{ |env| [200, {}, ["/users#{env['PATH_INFO']}\n"]] }
profiles_api = lambda{ |env| [200, {}, ["/profiles#{env['PATH_INFO']}\n"]] }

run Jellyfish::Builder.app{
  map '/users/me', to: '/me' do
    run profiles_api
  end
  map '/profiles' do
    run profiles_api
  end
  map '/users' do
    run users_api
  end
}
```

<!---
GET /users/me
[200, {}, ["/profiles/me\n"]]

GET /users/list
[200, {}, ["/users/list\n"]]

GET /profiles/me
[200, {}, ["/profiles/me\n"]]

GET /profiles/list
[200, {}, ["/profiles/list\n"]]
-->

##### Extension: Jellyfish::Rewrite (`rewrite rules`)

Note that `rewrite` takes a hash which could contain more than one rule:

``` ruby
require 'jellyfish'

profiles_api = lambda{ |env| [200, {}, ["/profiles#{env['PATH_INFO']}\n"]] }

run Jellyfish::Builder.app{
  rewrite '/users/me' => '/me',
          '/users/fa' => '/fa' do
    run profiles_api
  end
}
```

<!---
GET /users/me
[200, {}, ["/profiles/me\n"]]

GET /users/fa
[200, {}, ["/profiles/fa\n"]]
-->

### Extension: NormalizedParams (with force_encoding)

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::NormalizedParams

  get %r{^/(?<id>\d+)$} do
    "Jelly ##{params[:id]}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /123
[200,
 {'Content-Length' => '11', 'Content-Type' => 'text/plain'},
 ["Jelly #123\n"]]
-->

### Extension: NormalizedPath (with unescaping)

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::NormalizedPath

  get "/\u{56e7}" do
    "#{env['PATH_INFO']}=#{path_info}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /%E5%9B%A7
[200,
 {'Content-Length' => '16', 'Content-Type' => 'text/plain'},
 ["/%E5%9B%A7=/\u{56e7}\n"]]
-->

### Extension: Using multiple extensions with custom controller

Note that the controller should be assigned lastly in order to include
modules remembered in controller_include.

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  class MyController < Jellyfish::Controller
    include Jellyfish::WebSocket
  end
  controller_include NormalizedParams, NormalizedPath
  controller MyController

  get %r{^/(?<id>\d+)$} do
    "Jelly ##{params[:id]} jumps.\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /123
[200,
 {'Content-Length' => '18', 'Content-Type' => 'text/plain'},
 ["Jelly #123 jumps.\n"]]
-->

### Jellyfish as a middleware

If the Jellyfish middleware cannot find a corresponding action, it would
then forward the request to the lower application. We call this `cascade`.

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    "30\u{2103}\n"
  end
end

class Tank
  include Jellyfish
  get '/' do
    "Jelly Kelly\n"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
use Heater
run Tank.new
```

<!---
GET /
[200,
 {'Content-Length' => '12', 'Content-Type' => 'text/plain'},
 ["Jelly Kelly\n"]]
-->

### Modify response as a middleware

We could also explicitly call the lower app. This would give us more
flexibility than simply forwarding it.

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    status, headers, body = jellyfish.app.call(env)
    self.status  status
    self.headers headers
    self.body    body
    headers_merge('X-Temperature' => "30\u{2103}")
  end
end

class Tank
  include Jellyfish
  get '/status' do
    "See header X-Temperature\n"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
use Heater
run Tank.new
```

<!---
GET /status
[200,
 {'Content-Length' => '25', 'Content-Type' => 'text/plain',
  'X-Temperature'  => "30\u{2103}"},
 ["See header X-Temperature\n"]]
-->

### Override cascade for customized forwarding

We could also override `cascade` in order to craft custom response when
forwarding is happening. Note that whenever this forwarding is happening,
Jellyfish won't try to merge the headers from `dispatch` method, because
in this case Jellyfish is served as a pure proxy. As result we need to
explicitly merge the headers if we really want.

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  controller_include Module.new{
    def dispatch
      headers_merge('X-Temperature' => "35\u{2103}")
      super
    end

    def cascade
      status, headers, body = jellyfish.app.call(env)
      halt [status, headers_merge(headers), body]
    end
  }
end

class Tank
  include Jellyfish
  get '/status' do
    "\n"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
use Heater
run Tank.new
```

<!---
GET /status
[200,
 {'Content-Length' => '1', 'Content-Type' => 'text/plain',
  'X-Temperature'  => "35\u{2103}"},
 ["\n"]]
-->

### Simple before action as a middleware

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    env['temperature'] = 30
    cascade
  end
end

class Tank
  include Jellyfish
  get '/status' do
    "#{env['temperature']}\u{2103}\n"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
use Heater
run Tank.new
```

<!---
GET /status
[200,
 {'Content-Length' => '6', 'Content-Type' => 'text/plain'},
 ["30\u{2103}\n"]]
-->

### One huge tank

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    "30\u{2103}\n"
  end
end

class Tank
  include Jellyfish
  get '/' do
    "Jelly Kelly\n"
  end
end

HugeTank = Rack::Builder.app do
  use Rack::ContentLength
  use Rack::ContentType, 'text/plain'
  use Heater
  run Tank.new
end

run HugeTank
```

<!---
GET /status
[200,
 {'Content-Length' => '6', 'Content-Type' => 'text/plain'},
 ["30\u{2103}\n"]]
-->

### Raise exceptions

``` ruby
require 'jellyfish'
class Protector
  include Jellyfish
  handle StandardError do |e|
    "Protected: #{e}\n"
  end
end

class Tank
  include Jellyfish
  handle_exceptions false # default is true, setting false here would make
                          # the outside Protector handle the exception
  get '/' do
    raise "Oops, tank broken"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
use Protector
run Tank.new
```

<!---
GET /
[200,
 {'Content-Length' => '29', 'Content-Type' => 'text/plain'},
 ["Protected: Oops, tank broken\n"]]
-->

### Chunked transfer encoding (streaming) with Jellyfish::ChunkedBody

You would need a proper server setup.
Here's an example with Rainbows and fibers:

``` ruby
class Tank
  include Jellyfish
  get '/chunked' do
    ChunkedBody.new{ |out|
      (0..4).each{ |i| out.call("#{i}\n") }
    }
  end
end
use Rack::Chunked
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /chunked
[200,
 {'Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked'},
 ["2\r\n0\n\r\n", "2\r\n1\n\r\n", "2\r\n2\n\r\n",
  "2\r\n3\n\r\n", "2\r\n4\n\r\n", "0\r\n", "\r\n"]]
-->

### Chunked transfer encoding (streaming) with custom body

``` ruby
class Tank
  include Jellyfish
  class Body
    def each
      (0..4).each{ |i| yield "#{i}\n" }
    end
  end
  get '/chunked' do
    Body.new
  end
end
use Rack::Chunked
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /chunked
[200,
 {'Content-Type' => 'text/plain', 'Transfer-Encoding' => 'chunked'},
 ["2\r\n0\n\r\n", "2\r\n1\n\r\n", "2\r\n2\n\r\n",
  "2\r\n3\n\r\n", "2\r\n4\n\r\n", "0\r\n", "\r\n"]]
-->

### Server Sent Event (SSE)

``` ruby
class Tank
  include Jellyfish
  class Body
    def each
      (0..4).each{ |i| yield "data: #{i}\n\n" }
    end
  end
  get '/sse' do
    headers_merge('Content-Type' => 'text/event-stream')
    Body.new
  end
end
run Tank.new
```

<!---
GET /sse
[200,
 {'Content-Type' => 'text/event-stream'},
 ["data: 0\n\n", "data: 1\n\n", "data: 2\n\n", "data: 3\n\n", "data: 4\n\n"]]
-->

### Server Sent Event (SSE) with Rack Hijacking

``` ruby
class Tank
  include Jellyfish
  get '/sse' do
    headers_merge(
      'Content-Type' => 'text/event-stream',
      'rack.hijack'  => lambda do |sock|
        (0..4).each do |i|
          sock.write("data: #{i}\n\n")
        end
        sock.close
      end)
  end
end
run Tank.new
```

<!---
GET /sse
[200,
 {'Content-Type' => 'text/event-stream'},
 ["data: 0\n\n", "data: 1\n\n", "data: 2\n\n", "data: 3\n\n", "data: 4\n\n"]]
-->

### Using WebSocket

Note that this only works for Rack servers which support [hijack][].
You're better off with a threaded server such as [Rainbows!][] with
thread based concurrency model, or [Puma][].

Event-driven based server is a whole different story though. Since
EventMachine is basically dead, we could see if there would be a
[Celluloid-IO][] based web server production ready in the future,
so that we could take the advantage of event based approach.

[hijack]: http://www.rubydoc.info/github/rack/rack/file/SPEC#Hijacking
[Rainbows!]: http://rainbows.bogomips.org/
[Puma]: http://puma.io/
[Celluloid-IO]: https://github.com/celluloid/celluloid-io

``` ruby
class Tank
  include Jellyfish
  controller_include Jellyfish::WebSocket
  get '/echo' do
    switch_protocol do |msg|
      ws_write(msg)
    end
    ws_write('Hi!')
    ws_start
  end
end
run Tank.new
```

<!---
GET /echo
sock.string.should.eq <<-HTTP.chomp.force_encoding('ASCII-8BIT')
HTTP/1.1 101 Switching Protocols\r
Upgrade: websocket\r
Connection: Upgrade\r
Sec-WebSocket-Accept: Kfh9QIsMVZcl6xEPYxPHzW8SZ8w=\r
\r
\x81\x03Hi!
HTTP
[200, {}, ['']]
-->

## CONTRIBUTORS:

* Fumin (@fumin)
* Jason R. Clark (@jasonrclark)
* Lin Jen-Shin (@godfat)

## LICENSE:

Apache License 2.0 (Apache-2.0)

Copyright (c) 2012-2021, Lin Jen-Shin (godfat)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
