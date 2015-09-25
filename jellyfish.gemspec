# -*- encoding: utf-8 -*-
# stub: jellyfish 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "jellyfish"
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2015-09-25"
  s.description = "Pico web framework for building API-centric web applications.\nFor Rack applications or Rack middleware. Around 250 lines of code.\n\nCheck [jellyfish-contrib][] for extra extensions.\n\n[jellyfish-contrib]: https://github.com/godfat/jellyfish-contrib"
  s.email = ["godfat (XD) godfat.org"]
  s.files = [
  ".gitignore",
  ".gitmodules",
  ".travis.yml",
  "CHANGES.md",
  "Gemfile",
  "LICENSE",
  "README.md",
  "Rakefile",
  "TODO.md",
  "bench/bench_builder.rb",
  "config.ru",
  "jellyfish.gemspec",
  "jellyfish.png",
  "lib/jellyfish.rb",
  "lib/jellyfish/builder.rb",
  "lib/jellyfish/chunked_body.rb",
  "lib/jellyfish/json.rb",
  "lib/jellyfish/newrelic.rb",
  "lib/jellyfish/normalized_params.rb",
  "lib/jellyfish/normalized_path.rb",
  "lib/jellyfish/public/302.html",
  "lib/jellyfish/public/404.html",
  "lib/jellyfish/public/500.html",
  "lib/jellyfish/test.rb",
  "lib/jellyfish/urlmap.rb",
  "lib/jellyfish/version.rb",
  "lib/jellyfish/websocket.rb",
  "task/README.md",
  "task/gemgem.rb",
  "test/rack/test_builder.rb",
  "test/rack/test_urlmap.rb",
  "test/sinatra/test_base.rb",
  "test/sinatra/test_chunked_body.rb",
  "test/sinatra/test_error.rb",
  "test/sinatra/test_routing.rb",
  "test/test_from_readme.rb",
  "test/test_inheritance.rb",
  "test/test_log.rb",
  "test/test_misc.rb",
  "test/test_threads.rb",
  "test/test_websocket.rb"]
  s.homepage = "https://github.com/godfat/jellyfish"
  s.licenses = ["Apache License 2.0"]
  s.rubygems_version = "2.4.8"
  s.summary = "Pico web framework for building API-centric web applications."
  s.test_files = [
  "test/rack/test_builder.rb",
  "test/rack/test_urlmap.rb",
  "test/sinatra/test_base.rb",
  "test/sinatra/test_chunked_body.rb",
  "test/sinatra/test_error.rb",
  "test/sinatra/test_routing.rb",
  "test/test_from_readme.rb",
  "test/test_inheritance.rb",
  "test/test_log.rb",
  "test/test_misc.rb",
  "test/test_threads.rb",
  "test/test_websocket.rb"]
end
