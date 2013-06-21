# Jellyfish[![Build Status](https://secure.travis-ci.org/godfat/jellyfish.png?branch=master)](http://travis-ci.org/godfat/jellyfish)

by Lin Jen-Shin ([godfat](http://godfat.org))

![logo](https://github.com/godfat/jellyfish/raw/master/jellyfish.png)

## LINKS:

* [github](https://github.com/godfat/jellyfish)
* [rubygems](https://rubygems.org/gems/jellyfish)
* [rdoc](http://rdoc.info/github/godfat/jellyfish)

## DESCRIPTION:

Pico web framework for building API-centric web applications.
For Rack applications or Rack middlewares. Around 200 lines of code.

## DESIGN:

* Learn the HTTP way instead of using some pointless helpers
* Learn the Rack way instead of wrapping Rack functionalities, again
* Learn regular expression for routes instead of custom syntax
* Embrace simplicity over convenience
* Don't make things complicated only for _some_ convenience, but
  _great_ convenience, or simply stay simple for simplicity.
* More features are added as extensions

## FEATURES:

* Minimal
* Simple
* Modular
* No templates (You could use [tilt](https://github.com/rtomayko/tilt))
* No ORM
* No `dup` in `call`
* Regular expression routes, e.g. `get %r{^/(?<id>\d+)$}`
* String routes, e.g. `get '/'`
* Custom routes, e.g. `get Matcher.new`
* Build for either Rack applications or Rack middleware
* Include extensions for more features (There's a Sinatra extension)

## WHY?

Because Sinatra is too complex and inconsistent for me.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 1.9.3, 2.0.0, Rubinius and JRuby.

## INSTALLATION:

    gem install jellyfish

## SYNOPSIS:

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
GET /lookup
body = File.read("#{File.dirname(
  File.expand_path(__FILE__))}/../lib/jellyfish/public/302.html").
  gsub('VAR_URL', ':///')
[302,
 {'Content-Length' => body.bytesize.to_s, 'Content-Type' => 'text/html',
  'Location' => ':///'},
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
         "No one hears you: (eval):9:in `Tank'\n"
       when 'rbx'
         "No one hears you: kernel/delta/kernel.rb:81:in `yell (method_missing)'\n"
       else
         "No one hears you: (eval):9:in `block in <class:Tank>'\n"
       end
[403,
 {'Content-Length' => body.bytesize.to_s, 'Content-Type' => 'text/plain'},
 [body]]
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

### Extension: MultiActions (Filters)

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::MultiActions

  get do # wildcard before filter
    @state = 'jumps'
  end
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

### Extension: Sinatra flavoured controller

It's an extension collection contains:

* MultiActions
* NormalizedParams
* NormalizedPath

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::Sinatra

  get do # wildcard before filter
    @state = 'jumps'
  end
  get %r{^/(?<id>\d+)$} do
    "Jelly ##{params[:id]} #{@state}.\n"
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

### Extension: NewRelic

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::NewRelic

  get '/' do
    "OK\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
require 'cgi' # newrelic dev mode needs this and it won't require it itself
require 'new_relic/rack/developer_mode'
use NewRelic::Rack::DeveloperMode # GET /newrelic to read stats
run Tank.new
NewRelic::Agent.manual_start(:developer_mode => true)
```

<!---
GET /
[200,
 {'Content-Length' => '3', 'Content-Type' => 'text/plain'},
 ["OK\n"]]
-->

### Extension: Using multiple extensions with custom controller

This is effectively the same as using Jellyfish::Sinatra extension.
Note that the controller should be assigned lastly in order to include
modules remembered in controller_include.

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  class MyController < Jellyfish::Controller
    include Jellyfish::MultiActions
  end
  controller_include NormalizedParams, NormalizedPath
  controller MyController

  get do # wildcard before filter
    @state = 'jumps'
  end
  get %r{^/(?<id>\d+)$} do
    "Jelly ##{params[:id]} #{@state}.\n"
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

### Default headers as a middleware

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    status, headers, body = jellyfish.app.call(env)
    self.status  status
    self.headers({'X-Temperature' => "30\u{2103}"}.merge(headers))
    self.body    body
  end
end

class Tank
  include Jellyfish
  get '/status' do
    headers_merge('X-Temperature' => "35\u{2103}")
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
    forward
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

### Halt in before action

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  controller_include Jellyfish::MultiActions

  get do # wildcard before filter
    body "Done!\n"
    halt
  end
  get '/' do
    "Never reach.\n"
  end
end

use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

<!---
GET /status
[200,
 {'Content-Length' => '6', 'Content-Type' => 'text/plain'},
 ["Done!\n"]]
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

HugeTank = Rack::Builder.new do
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
  handle Exception do |e|
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
  "2\r\n3\n\r\n", "2\r\n4\n\r\n", "0\r\n\r\n"]]
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
  "2\r\n3\n\r\n", "2\r\n4\n\r\n", "0\r\n\r\n"]]
-->

## CONTRIBUTORS:

* Lin Jen-Shin (@godfat)

## LICENSE:

Apache License 2.0

Copyright (c) 2012-2013, Lin Jen-Shin (godfat)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
