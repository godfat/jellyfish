#!/usr/bin/env unicorn -N -Ilib

require 'jellyfish'

class Jelly
  include Jellyfish

  controller_include Module.new{
    def dispatch
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
     :description =>
       'This is a simple example for using Jellyfish and' \
       ' Swagger UI altogether. You could also try the'   \
       ' <a href="http://swagger.wordnik.com/">official Swagger UI app</a>,' \
       ' and fill it with the swagger URL.'
     }
  end

  def self.swagger_apiVersion
    '1.0.0'
  end

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

  get '/users',
    :summary => 'List users',
    :notes   => 'Note that we do not really have users.' do
    render [:name => 'jellyfish']
  end

  post '/users',
    :summary => 'Create a user',
    :notes   => 'Here we demonstrate how to write the swagger doc.',
    :parameters => {:name => {:type => :string, :required => true,
                              :description => 'The name of the user'},
                    :sane => {:type => :boolean,
                              :description => 'If the user is sane'},
                    :type => {:type => :string,
                              :description => 'What kind of user',
                              :enum => %w[good neutral evil]}},
    :responseMessages => [{:code => 400, :message => 'Invalid name'}] do
    render :message => "jellyfish #{request.params['name']} created."
  end

  put %r{\A/users/(?<id>\d+)},
    :summary => 'Update a user',
    :parameters => {:id => {:type => :integer,
                            :description => 'The id of the user'}} do |match|
    render :message => "jellyfish ##{match[:id]} updated."
  end

  delete %r{\A/users/(?<id>\d+)} do |match|
    render :message => "jellyfish ##{match[:id]} deleted."
  end

  get %r{\A/posts/(?<year>\d+)-(?<month>\d+)/(?<name>\w+)},
    :summary => 'Get a post' do |match|
    render Hash[match.names.zip(match.captures)]
  end

  get '/posts/tags/ruby' do
    render []
  end
end

App = Rack::Builder.app do
  use Rack::CommonLogger
  use Rack::Chunked
  use Rack::ContentLength
  use Rack::Deflater

  map '/swagger' do
    run Jellyfish::Swagger.new('', Jelly)
  end

  run Rack::Cascade.new([Rack::File.new('public/index.html'),
                         Rack::File.new('public'),
                         Jelly.new])
end

run App
