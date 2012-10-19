# CHANGES

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
