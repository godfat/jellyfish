# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "jellyfish"
  s.version = "0.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lin Jen-Shin (godfat)"]
  s.date = "2012-10-18"
  s.description = "Pico web framework for building API-centric web applications, either\nRack applications or Rack middlewares. Under 200 lines of code."
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
  "lib/jellyfish.rb",
  "lib/jellyfish/public/302.html",
  "lib/jellyfish/public/404.html",
  "lib/jellyfish/public/500.html",
  "lib/jellyfish/sinatra.rb",
  "lib/jellyfish/test.rb",
  "lib/jellyfish/version.rb",
  "sinatra/builder_test.rb",
  "sinatra/coffee_test.rb",
  "sinatra/contest.rb",
  "sinatra/creole_test.rb",
  "sinatra/delegator_test.rb",
  "sinatra/encoding_test.rb",
  "sinatra/erb_test.rb",
  "sinatra/extensions_test.rb",
  "sinatra/filter_test.rb",
  "sinatra/haml_test.rb",
  "sinatra/helper.rb",
  "sinatra/helpers_test.rb",
  "sinatra/integration/app.rb",
  "sinatra/integration_helper.rb",
  "sinatra/integration_test.rb",
  "sinatra/less_test.rb",
  "sinatra/liquid_test.rb",
  "sinatra/mapped_error_test.rb",
  "sinatra/markaby_test.rb",
  "sinatra/markdown_test.rb",
  "sinatra/middleware_test.rb",
  "sinatra/nokogiri_test.rb",
  "sinatra/rack_test.rb",
  "sinatra/radius_test.rb",
  "sinatra/rdoc_test.rb",
  "sinatra/readme_test.rb",
  "sinatra/request_test.rb",
  "sinatra/response_test.rb",
  "sinatra/result_test.rb",
  "sinatra/route_added_hook_test.rb",
  "sinatra/routing_test.rb",
  "sinatra/sass_test.rb",
  "sinatra/scss_test.rb",
  "sinatra/server_test.rb",
  "sinatra/settings_test.rb",
  "sinatra/sinatra_test.rb",
  "sinatra/slim_test.rb",
  "sinatra/static_test.rb",
  "sinatra/streaming_test.rb",
  "sinatra/templates_test.rb",
  "sinatra/textile_test.rb",
  "task/.gitignore",
  "task/gemgem.rb",
  "test/sinatra/test_base.rb"]
  s.homepage = "https://github.com/godfat/jellyfish"
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.24"
  s.summary = "Pico web framework for building API-centric web applications, either"
  s.test_files = ["test/sinatra/test_base.rb"]

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rack>, [">= 0"])
    else
      s.add_dependency(%q<rack>, [">= 0"])
    end
  else
    s.add_dependency(%q<rack>, [">= 0"])
  end
end
