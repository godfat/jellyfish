# -*- encoding: utf-8 -*-
# stub: jellyfish 0.9.2 ruby lib

Gem::Specification.new do |s|
  s.name = "jellyfish"
  s.version = "0.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2013-09-29"
  s.description = "Pico web framework for building API-centric web applications.\nFor Rack applications or Rack middlewares. Around 250 lines of code."
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
  "jellyfish.gemspec",
  "jellyfish.png",
  "lib/jellyfish.rb",
  "lib/jellyfish/chunked_body.rb",
  "lib/jellyfish/multi_actions.rb",
  "lib/jellyfish/newrelic.rb",
  "lib/jellyfish/normalized_params.rb",
  "lib/jellyfish/normalized_path.rb",
  "lib/jellyfish/public/302.html",
  "lib/jellyfish/public/404.html",
  "lib/jellyfish/public/500.html",
  "lib/jellyfish/sinatra.rb",
  "lib/jellyfish/test.rb",
  "lib/jellyfish/version.rb",
  "task/.gitignore",
  "task/gemgem.rb",
  "test/sinatra/test_base.rb",
  "test/sinatra/test_chunked_body.rb",
  "test/sinatra/test_error.rb",
  "test/sinatra/test_multi_actions.rb",
  "test/sinatra/test_routing.rb",
  "test/test_from_readme.rb",
  "test/test_inheritance.rb",
  "test/test_threads.rb"]
  s.homepage = "https://github.com/godfat/jellyfish"
  s.licenses = ["Apache License 2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "2.1.5"
  s.summary = "Pico web framework for building API-centric web applications."
  s.test_files = [
  "test/sinatra/test_base.rb",
  "test/sinatra/test_chunked_body.rb",
  "test/sinatra/test_error.rb",
  "test/sinatra/test_multi_actions.rb",
  "test/sinatra/test_routing.rb",
  "test/test_from_readme.rb",
  "test/test_inheritance.rb",
  "test/test_threads.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
      s.add_development_dependency(%q<muack>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<bacon>, [">= 0"])
      s.add_dependency(%q<muack>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<bacon>, [">= 0"])
    s.add_dependency(%q<muack>, [">= 0"])
  end
end
