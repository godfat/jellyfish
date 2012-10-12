# Jellyfish

by Lin Jen-Shin ([godfat](http://godfat.org))

## LINKS:

* [github](https://github.com/godfat/jellyfish)
* [rubygems](https://rubygems.org/gems/jellyfish)
* [rdoc](http://rdoc.info/github/godfat/jellyfish)

## DESCRIPTION:

Pico web framework for building API-centric web applications, either
Rack applications or Rack middlewares. Under 200 lines of code.

## DESIGN:

* Learn HTTP
* Learn Rack
* Learn regular expression for routes
* Embrace simplicity over convenience
* Don't make things complicated only for _some_ convenience, but
  _great_ convenience, or simply stay simple for simplicity.

## FEATURES:

* Minimal
* Simple
* No templates
* No ORM
* String routes, e.g. `get '/'`
* Regular expression routes, e.g. `get %r{/(\d+)}`
* Build either Rack applications or Rack middlewares

## WHY?

Because Sinatra is too complex and inconsistent for me.

## REQUIREMENTS:

* Tested with MRI (official CRuby) 1.9.3, Rubinius and JRuby.

## INSTALLATION:

    gem install jellyfish

## SYNOPSIS:

Your lovely config.ru:

``` ruby
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
