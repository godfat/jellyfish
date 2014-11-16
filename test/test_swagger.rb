
require 'jellyfish/test'

describe Jellyfish do
  paste :jellyfish

  app = Rack::Builder.app do
    eval File.read("#{File.dirname(__FILE__)}/../config.ru")
  end

  def string_keys hash
    hash.inject({}){ |r, (k, v)| r[k.to_s] = v; r }
  end

  would '/swagger' do
    status, headers, body = get('/swagger', app)
    status                 .should.eq 200
    headers['Content-Type'].should.eq 'application/json; charset=utf-8'
    res = Jellyfish::Json.decode(body.to_a.join)
    res['swaggerVersion'].should.eq '1.2'
    res['info']          .should.eq string_keys(Jelly.info)
    res['apiVersion']    .should.eq Jelly.swagger_apiVersion
    res['apis']          .should.eq \
      [{'path' => '/users'}, {'path' => '/posts'}]
  end

  would '/swagger/users' do
    status, _, body = get('/swagger/users', app)
    status                 .should.eq 200
    res = Jellyfish::Json.decode(body.to_a.join)
    res['basePath']    .should.eq 'https://localhost:8080'
    res['resourcePath'].should.eq '/users'
    res['apis']        .should.eq \
      [{"path"=>"/users",
        "operations"=>[{"summary"=>"List users",
                        "notes"=>"List users<br>Note that we do not really" \
                                 " have users.",
                        "path"=>"/users",
                        "method"=>"GET",
                        "nickname"=>"/users",
                        "parameters"=>[]},
                       {"summary"=>"Create a user",
                        "notes"=>"Create a user<br>Here we demonstrate how" \
                                 " to write the swagger doc.",
                        "parameters"=>[{"type"=>"string",
                                        "required"=>true,
                                        "description"=>"The name of the user",
                                        "name"=>"name",
                                        "paramType"=>"query"},
                                       {"type"=>"boolean",
                                        "description"=>"If the user is sane",
                                        "name"=>"sane",
                                        "required"=>false,
                                        "paramType"=>"query"},
                                       {"type"=>"string",
                                        "description"=>"What kind of user",
                                        "enum"=>["good", "neutral", "evil"],
                                        "name"=>"type",
                                        "required"=>false,
                                        "paramType"=>"query"}],
                        "responseMessages"=>[{"code"=>400,
                                              "message"=>"Invalid name"}],
                        "path"=>"/users",
                        "method"=>"POST",
                        "nickname"=>"/users"}]},
       {"path"=>"/users/{id}",
        "operations"=>[{"summary"=>"Update a user",
                        "parameters"=>[{"type"=>"integer",
                                        "description"=>"The id of the user",
                                        "name"=>"id",
                                        "required"=>true,
                                        "paramType"=>"path"}],
                        "path"=>"/users",
                        "method"=>"PUT",
                        "nickname"=>"/users/{id}",
                        "notes"=>"Update a user"},
                       {"path"=>"/users",
                        "method"=>"DELETE",
                        "nickname"=>"/users/{id}",
                        "summary"=>nil,
                        "notes"=>nil,
                        "parameters"=>[{"name"=>"id",
                                        "type"=>"integer",
                                        "required"=>true,
                                        "paramType"=>"path"}]}]}]
  end

  swagger = Jellyfish::Swagger.new(Class.new{include Jellyfish})

  would 'swagger_path' do
    swagger.send(:swagger_path, '/')          .should.eq '/'
    swagger.send(:swagger_path, '/users/{id}').should.eq '/users'
  end

  would 'nickname' do
    swagger.send(:nickname, '/')                    .should.eq '/'
    swagger.send(:nickname, '/users/{id}')          .should.eq '/users/{id}'
    swagger.send(:nickname, %r{\A/users/(?<id>\d+)}).should.eq '/users/{id}'
    swagger.send(:nickname, %r{^/users/(?<id>\d+)$}).should.eq '/users/{id}'
    swagger.send(:nickname, %r{/(?<a>\d)/(?<b>\w)$}).should.eq '/{a}/{b}'
  end

  would 'notes' do
    swagger.send(:notes, :summary => 'summary', :notes => 'notes').
      should.eq 'summary<br>notes'
    swagger.send(:notes, :summary => 'summary').
      should.eq 'summary'
  end

  would 'path_parameters' do
    swagger.send(:path_parameters, %r{/(?<a>\d)/(?<b>\w)/(?<c>\d)$},
                 :parameters => {:c => {:type => 'hash'}}).
      should.eq([{:name => 'a', :type => 'integer',
                  :required => true, :paramType => 'path'},
                 {:name => 'b', :type => 'string',
                  :required => true, :paramType => 'path'},
                 {:name => 'c', :type => 'hash',
                  :required => true, :paramType => 'path'}])
  end

  would 'query_parameters' do
    swagger.send(:query_parameters,
                 :parameters => {:c => {:type => 'hash'}}).
      should.eq([:name => 'c', :type => 'hash',
                 :required => false, :paramType => 'query'])
    swagger.send(:query_parameters,
                 :parameters => {:c => {:required => true}}).
      should.eq([:name => 'c', :type => 'string',
                 :required => true, :paramType => 'query'])
  end
end
