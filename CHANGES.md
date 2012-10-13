# CHANGES

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
