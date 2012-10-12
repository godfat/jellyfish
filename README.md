# Jellyfish

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/jellyfish)
* [rubygems](https://rubygems.org/gems/jellyfish)
* [rdoc](http://rdoc.info/github/godfat/jellyfish)

## DESCRIPTION:

Nano framework for building API web application. Under 200 lines of codes.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 1.9.3, Rubinius and JRuby.

## INSTALLATION:

    gem install jellyfish

## SYNOPSIS:

Your lovely config.ru:

``` ruby
require 'jellyfish'

class Tank
  extend Jellyfish
  get '/' do |match|
    "Jelly Kelly\n"
  end

  get /(\d+)/ do |match|
    "Jelly ##{match[1]}\n"
  end
end

use Rack::ContentLength
run Tank
```

## CONTRIBUTORS:

* Lin Jen-Shin (@godfat)

## LICENSE:

Apache License 2.0

Copyright (c) 2012, Lin Jen-Shin (godfat)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

<http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
