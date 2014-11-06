# CHANGES

## Jellyfish 1.0.1 -- 2014-11-07

### Enhancements for Jellyfish core

* Now `Jellyfish.handle` could take multiple exceptions as the arguments.

### Other enhancements

* Introduced `Jellyfish::WebSocket` for basic websocket support.

## Jellyfish 1.0.0 -- 2014-03-17

### Incompatible changes

* Renamed `forward` to `cascade` to better aligned with Rack.

### Enhancements for Jellyfish core

* Introduced `log` and `log_error` for for controllers.
* Introduced `not_found` to trigger 404 response.
* Now we separate the idea of 404 and cascade. Use `not_found` for 404
  responses, and `cascade` for forwarding requests.

### Other enhancements

* Now we have Jellyfish::Swagger to generate Swagger documentation.
  Read README.md for more detail or checkout config.ru for a full example.

## Jellyfish 0.9.2 -- 2013-09-26

* Do not rescue Exception since we don't really want to rescue something
  like SignalException, which would break signal handling.

## Jellyfish 0.9.1 -- 2013-08-23

* Fixed a thread safety bug for initializing exception handlers.

## Jellyfish 0.9.0 -- 2013-07-11

### Enhancements for Jellyfish core

* We no longer use exceptions to control the flow. Use
  `halt(InternalError.new)` instead. However, raising exceptions
  would still work. Just prefer to use `halt` if you would like
  some performance boost.

### Incompatible changes

* If you're raising `NotFound` instead of using `forward` in your app,
  it would no longer forward the request but show a 404 page. Always
  use `forward` if you intend to forward the request.

## Jellyfish 0.8.0 -- 2013-06-15

### Incompatible changes

* Now there's no longer Jellyfish#controller but Jellyfish.controller,
  as there's no much point for making the controller per-instance.
  You do this to override the controller method instead:

``` ruby
class MyApp
  include Jellyfish
  def self.controller
    MyController
  end
  class MyController < Jellyfish::Controller
    def hi
      'hi'
    end
  end
  get{ hi }
end
```

* You can also change the controller by assigning it. The same as above:

``` ruby
class MyApp
  include Jellyfish
  class MyController < Jellyfish::Controller
    def hi
      'hi'
    end
  end
  controller MyController
  get{ hi }
end
```

### Enhancements for Jellyfish core

* Introduced Jellyfish.controller_include which makes it easy to pick
  modules to be included in built-in controller.
* Introduced Controller#halt as a short hand for `throw :halt`
* Now default route is `//`. Using `get{ 'Hello, World!' }` is effectively
  the same as `get(//){ 'Hello, World!' }`
* Now inheritance works.
* Now it raises TypeError if passing a route doesn't respond to :match.
* Now Jellyfish would find the most suitable error handler to handle
  errors, i.e. It would find the error handler which would handle the
  nearest exception class in the ancestors chain. Previously it would
  only find the first one which matches, ignoring the rest. It would
  also cache the result upon a lookup.

### Enhancements for Jellyfish extension

* Added `Jellyfish::ChunkedBody` which is similar to `Sinatra::Stream`.

* Added `Jellyfish::MultiAction` which gives you some kind of ability to do
  before or after filters. See README.md for usage.

* Added `Jellyfish::NormalizedParams` which gives you some kind of Sinatra
  flavoured params.

* Added `Jellyfish::NormalizedPath` which would unescape incoming PATH_INFO
  so you could match '/f%C3%B6%C3%B6' with '/föö'.

### Enhancements for Jellyfish::Sinatra

* Now `Jellyfish::Sinatra` includes `Jellyfish::MultiAction`,
  `Jellyfish::NormalizedParams`, and `Jellyfish::NormalizedPath`.

## Jellyfish 0.6.0 -- 2012-11-02

### Enhancements for Jellyfish core

* Extracted Jellyfish::Controller#call and Jellyfish::Controller#block_call
  into Jellyfish::Controller::Call so that you can have modules which can
  override call and block_call. See Jellyfish::Sinatra and Jellyfish::NewRelic
  for an example.

* Now you can use `request` in the controller, which is essentially:
  `@request ||= Rack::Request.new(env)`. This also means you would need
  Rack installed and required to use it. Other than this, there's no
  strict requirement for Rack.

### Enhancements for NewRelic

* Added Jellyfish::NewRelic which makes you work easier with NewRelic.
  Here's an example of how to use it: (extracted from README)

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  class MyController < Jellyfish::Controller
    include Jellyfish::NewRelic
  end
  def controller; MyController; end
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

## Jellyfish 0.5.3 -- 2012-10-26

### Enhancements for Jellyfish core

* Respond an empty string response if the block gives a nil.
* Added Jellyfish#log method which allow you to use the same
  way as Jellyfish log things.
* rescue LocalJumpError and give a hint if you're trying to
  return or break from the block. You should use `next` instead.
  Or you can simply pass lambda which you can safely `return`.
  For example: `get '/path', &lambda{ return "body" }`

### Enhancements for Sinatra flavored controller

* Introduced `initialize_params` and only initialize them whenever
  it's not yet set, giving you the ability to initialize params
  before calling `block_call`, thus you can customize params more
  easily. An example for making NewRelic work would be like this:

``` ruby
class Controller < Api::Controller
  include NewRelic::Agent::Instrumentation::ControllerInstrumentation

  def block_call argument, block
    path = if argument.respond_to?(:regexp)
             argument.regexp
           else
             argument
           end.to_s[1..-1]
    name = "#{env['REQUEST_METHOD']} #{path}"
    initialize_params(argument)                     # magic category, see:
                      # NewRelic::MetricParser::WebTransaction::Jellyfish
    perform_action_with_newrelic_trace(:category => 'Controller/Jellyfish',
                                       :path     => path                  ,
                                       :name     => name                  ,
                                       :request  => request               ,
                                       :params   => params ){ super }
  end
end

module NewRelic::MetricParser::WebTransaction::Jellyfish
  include NewRelic::MetricParser::WebTransaction::Pattern
  def is_web_transaction?; true; end
  def category ; 'Jellyfish'; end
end
```

## Jellyfish 0.5.2 -- 2012-10-20

### Incompatible changes

* `protect` method is removed and inlined, reducing the size of call stack.

### Enhancements for Jellyfish core

* `log_error` is now a public method.

### Enhancements for Sinatra flavored controller

* Force params encoding to Encoding.default_external

## Jellyfish 0.5.1 -- 2012-10-19

* Removed accidentally added sinatra files.

## Jellyfish 0.5.0 -- 2012-10-18

### Incompatible changes

* Some internal constants are removed.
* Renamed `Respond` to `Response`.

### Enhancements

* Now Jellyfish would always use the custom error handler to handle the
  particular exception even if `handle_exceptions` set to false. That is,
  now setting `handle_exceptions` to false would only disable default
  error handling. This behavior makes more sense since if you want the
  exception bubble out then you shouldn't define the custom error handler
  in the first place. If you define it, you must mean you want to use it.

* Eliminated some uninitialized instance variable warnings.

* Now you can access the original app via `jellyfish` in the controller.

* `Jellyfish::Controller` no longer includes `Jellyfish`, which would remove
  those `DSL` methods accidentally included in previous version (0.4.0-).

## Jellyfish 0.4.0 -- 2012-10-14

* Now you can define your own custom controller like:

``` ruby
require 'jellyfish'
class Heater
  include Jellyfish
  get '/status' do
    temperature
  end

  def controller; Controller; end
  class Controller < Jellyfish::Controller
    def temperature
      "30\u{2103}\n"
    end
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Heater.new
```

* Now it's possible to use a custom matcher instead of regular expression:

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

* Added a Sinatra flavor controller

``` ruby
require 'jellyfish'
class Tank
  include Jellyfish
  def controller; Jellyfish::Sinatra; end
  get %r{^/(?<id>\d+)$} do
    "Jelly ##{params[:id]}\n"
  end
end
use Rack::ContentLength
use Rack::ContentType, 'text/plain'
run Tank.new
```

## Jellyfish 0.3.0 -- 2012-10-13

* Birthday!
