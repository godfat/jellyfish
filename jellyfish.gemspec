# -*- encoding: utf-8 -*-
# stub: jellyfish 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "jellyfish".freeze
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Lin Jen-Shin (godfat)".freeze]
  s.date = "2016-11-17"
  s.description = "Pico web framework for building API-centric web applications.\nFor Rack applications or Rack middleware. Around 250 lines of code.\n\nCheck [jellyfish-contrib][] for extra extensions.\n\n[jellyfish-contrib]: https://github.com/godfat/jellyfish-contrib".freeze
  s.email = ["godfat (XD) godfat.org".freeze]
  s.files = [
  ".gitignore".freeze,
  ".gitmodules".freeze,
  ".travis.yml".freeze,
  "CHANGES.md".freeze,
  "Gemfile".freeze,
  "LICENSE".freeze,
  "README.md".freeze,
  "Rakefile".freeze,
  "TODO.md".freeze,
  "bench/bench_builder.rb".freeze,
  "config.ru".freeze,
  "jellyfish.gemspec".freeze,
  "lib/jellyfish.rb".freeze,
  "lib/jellyfish/builder.rb".freeze,
  "lib/jellyfish/chunked_body.rb".freeze,
  "lib/jellyfish/json.rb".freeze,
  "lib/jellyfish/newrelic.rb".freeze,
  "lib/jellyfish/normalized_params.rb".freeze,
  "lib/jellyfish/normalized_path.rb".freeze,
  "lib/jellyfish/public/302.html".freeze,
  "lib/jellyfish/public/404.html".freeze,
  "lib/jellyfish/public/500.html".freeze,
  "lib/jellyfish/rewrite.rb".freeze,
  "lib/jellyfish/test.rb".freeze,
  "lib/jellyfish/urlmap.rb".freeze,
  "lib/jellyfish/version.rb".freeze,
  "lib/jellyfish/websocket.rb".freeze,
  "task/README.md".freeze,
  "task/gemgem.rb".freeze,
  "test/rack/test_builder.rb".freeze,
  "test/rack/test_urlmap.rb".freeze,
  "test/sinatra/test_base.rb".freeze,
  "test/sinatra/test_chunked_body.rb".freeze,
  "test/sinatra/test_error.rb".freeze,
  "test/sinatra/test_routing.rb".freeze,
  "test/test_from_readme.rb".freeze,
  "test/test_inheritance.rb".freeze,
  "test/test_log.rb".freeze,
  "test/test_misc.rb".freeze,
  "test/test_rewrite.rb".freeze,
  "test/test_threads.rb".freeze,
  "test/test_websocket.rb".freeze]
  s.homepage = "https://github.com/godfat/jellyfish".freeze
  s.licenses = ["Apache License 2.0".freeze]
  s.rubygems_version = "2.6.8".freeze
  s.summary = "Pico web framework for building API-centric web applications.".freeze
  s.test_files = [
  "test/rack/test_builder.rb".freeze,
  "test/rack/test_urlmap.rb".freeze,
  "test/sinatra/test_base.rb".freeze,
  "test/sinatra/test_chunked_body.rb".freeze,
  "test/sinatra/test_error.rb".freeze,
  "test/sinatra/test_routing.rb".freeze,
  "test/test_from_readme.rb".freeze,
  "test/test_inheritance.rb".freeze,
  "test/test_log.rb".freeze,
  "test/test_misc.rb".freeze,
  "test/test_rewrite.rb".freeze,
  "test/test_threads.rb".freeze,
  "test/test_websocket.rb".freeze]
end
