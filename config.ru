#!/usr/bin/env unicorn -N -Ilib

require 'jellyfish'

class Jelly
  include Jellyfish

  controller_include Module.new{
    def dispatch
      headers_merge 'content-type' => 'application/json; charset=utf-8',
                    'Access-Control-Allow-Origin' => '*'
      super
    end

    def render obj
      ["#{Jellyfish::Json.encode(obj)}\n"]
    end
  }

  handle Jellyfish::NotFound do |e|
    status 404
    body   %Q|{"error":{"name":"NotFound"}}\n|
  end

  handle StandardError do |error|
    jellyfish.log_error(error, env['rack.errors'])

    name    = error.class.name
    message = error.message

    status 500
    body render('error' => {'name' => name, 'message' => message})
  end

  get '/users' do
    render [:name => 'jellyfish']
  end

  post '/users' do
    render :message => "jellyfish #{request.params['name']} created."
  end

  put %r{\A/users/(?<id>\d+)} do |match|
    render :message => "jellyfish ##{match[:id]} updated."
  end

  delete %r{\A/users/(?<id>\d+)} do |match|
    render :message => "jellyfish ##{match[:id]} deleted."
  end

  get %r{\A/posts/(?<year>\d+)-(?<month>\d+)/(?<name>\w+)} do |match|
    render Hash[match.names.zip(match.captures)]
  end

  get '/posts/tags/ruby' do
    render []
  end
end

App = Jellyfish::Builder.app do
  use Rack::CommonLogger
  use Rack::ContentLength
  use Rack::Deflater

  run Rack::Cascade.new([Rack::File.new('public/index.html'),
                         Rack::File.new('public'),
                         Jelly.new])
end

run App
