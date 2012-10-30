# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "jellyfish"
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2012-10-31"
  s.description = "Pico web framework for building API-centric web applications.\nFor Rack applications or Rack middlewares. Under 200 lines of code."
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
  "example/config.ru",
  "example/rainbows.rb",
  "example/server.sh",
  "jellyfish.gemspec",
  "jellyfish.png",
  "lib/jellyfish.rb",
  "lib/jellyfish/newrelic.rb",
  "lib/jellyfish/public/302.html",
  "lib/jellyfish/public/404.html",
  "lib/jellyfish/public/500.html",
  "lib/jellyfish/sinatra.rb",
  "lib/jellyfish/test.rb",
  "lib/jellyfish/version.rb",
  "task/.gitignore",
  "task/gemgem.rb",
  "test/sinatra/test_base.rb"]
  s.homepage = "https://github.com/godfat/jellyfish"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Pico web framework for building API-centric web applications."
  s.test_files = ["test/sinatra/test_base.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rack>, [">= 0"])
      s.add_development_dependency(%q<bacon>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
      s.add_dependency(%q<bacon>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
    s.add_dependency(%q<bacon>, [">= 0"])
  end
end
