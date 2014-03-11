#!/usr/bin/env unicorn -N -Ilib

require 'jellyfish'

class Jelly
  include Jellyfish

  controller_include Module.new{
    def block_call argument, block
      headers_merge 'Content-Type' => 'application/json; charset=utf-8',
                    'Access-Control-Allow-Origin' => '*'
      super
    end

    def render obj
      ["#{Jellyfish::Json.encode(obj)}\n"]
    end
  }

  get '/users' do
    render :name => 'jellyfish'
  end

  get %r{\A/users/(?<id>\d+)} do |match|
    render :name => "jellyfish ##{match[:id]}"
  end
end

App = Rack::Builder.app do
  use Rack::CommonLogger
  use Rack::Chunked
  use Rack::ContentLength
  use Rack::Deflater

  map '/swagger' do
    run Jellyfish::Swagger.new(Jelly)
  end

  run Rack::Cascade.new([Rack::File.new('public/index.html'),
                         Rack::File.new('public'),
                         Jelly.new])
end

run App
