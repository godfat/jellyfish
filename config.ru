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

  def self.info
    {:title       => 'Jellyfish Swagger UI',
     :description => 'This is a simple example for using Jellyfish and' \
                     ' Swagger UI altogether.'}
  end

  def self.produces
    ['application/json']
  end

  get '/users', :summary => 'summary', :notes => 'notes' do
    render [:name => 'jellyfish']
  end

  post '/users', :summary => 'summary', :notes => 'notes' do
    render :message => 'jellyfish created.'
  end

  put %r{\A/users/(?<id>\d+)},
    :summary => 'Update a user', :notes => 'Update a user',
    :parameters => {:id => {:type => :integer,
                            :description => 'The id of the user'}} do |match|
    render :message => "jellyfish ##{match[:id]} updated."
  end

  delete %r{\A/users/(?<id>\d+)} do |match|
    render :message => "jellyfish ##{match[:id]} deleted."
  end

  get %r{\A/posts/(?<year>\d+)-(?<month>\d+)/(?<name>\w+)},
    :summary => 'summary', :notes => 'notes' do |match|
    render Hash[match.names.zip(match.captures)]
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
