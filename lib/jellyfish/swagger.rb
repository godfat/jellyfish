
require 'jellyfish/json'

module Jellyfish
  class Swagger
    include Jellyfish
    attr_reader :app, :swagger_apis, :jellyfish_apis
    controller_include Jellyfish::NormalizedPath, Module.new{
      def block_call argument, block
        headers_merge 'Content-Type' => 'application/json; charset=utf-8'
        super
      end
    }

    def initialize app
      @app = app
      @jellyfish_apis = app.routes.flat_map{ |meth, routes|
        routes.map do |(path, _)|
          nickname, params = if path.respond_to?(:source)
            [path.source.gsub(/\(\?<(\w+)>(.+)\)/, '{\1}').gsub(/\\\w+/, ''),
             path.names.map{ |name|
               {'name' => name, 'type' => 'integer',
                'description' => 'argument description',
                'required' => true, 'paramType' => 'path'}
             }]
          else
            [path.to_s, []]
          end
          {'method' => meth.to_s.upcase, 'summary' => 'api summary',
           'name' => nickname[%r{^/[^/]+}], 'parameters' => params,
           'nickname' => nickname}
        end
      }.group_by{ |api| api['name'] }.inject({}){ |r, (name, operations)|
        r[name] = operations.group_by{ |op| op['nickname'] }
        r
      }

      @swagger_apis = jellyfish_apis.keys.map do |name|
        {'path' => name}
      end
    end

    def swagger_info
      if app.respond_to?(:info)
        app.info
      else
        {}
      end
    end

    get '/' do
      [Jellyfish::Json.encode(
        'apiVersion'     => '1.0.0'               ,
        'swaggerVersion' => '1.2'                 ,
        'info'           => jellyfish.swagger_info,
        'apis'           => jellyfish.swagger_apis)]
    end

    get %r{\A/(?<name>.+)\Z} do |match|
      name     = "/#{match[:name]}"
      basePath = "#{request.scheme}://#{request.host_with_port}"

      apis = jellyfish.jellyfish_apis[name].map{ |nickname, operations|
        {'path' => nickname, 'operations' => operations}
      }

      [Jellyfish::Json.encode(
        'apiVersion'     => '1.0.0'             ,
        'swaggerVersion' => '1.2'               ,
        'basePath'       => basePath            ,
        'resourcePath'   => name                ,
        'produces'       => ['application/json'],
        'apis'           => apis                )]
    end
  end
end
