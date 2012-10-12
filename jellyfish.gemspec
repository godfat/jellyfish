# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "jellyfish"
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2012-10-13"
  s.description = "Pico web framework for building API-centric web applications, either\nRack applications or Rack middlewares. Under 200 lines of code."
  s.email = ["godfat (XD) godfat.org"]
  s.files = [
  ".gitmodules",
  ".travis.yml",
  "CHANGES.md",
  "LICENSE",
  "README.md",
  "Rakefile",
  "TODO.md",
  "config.ru",
  "lib/jellyfish.rb",
  "lib/jellyfish/public/302.html",
  "lib/jellyfish/public/404.html",
  "lib/jellyfish/public/500.html",
  "lib/jellyfish/version.rb",
  "task/.gitignore",
  "task/gemgem.rb"]
  s.homepage = "https://github.com/godfat/jellyfish"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Pico web framework for building API-centric web applications, either"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
