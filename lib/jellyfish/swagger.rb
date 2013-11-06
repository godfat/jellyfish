
module Jellyfish
  module Swagger
    module_function
    def inject jellyfish
      jellyfish_apis = jellyfish.routes.flat_map{ |meth, routes|
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

      swagger_apis = jellyfish_apis.keys.map do |name|
        {'path' => name}
      end

      jellyfish.get('/swagger') do
        o = {'apiVersion'     => '1.0.0',
             'swaggerVersion' => '1.2',
             'apis'           => swagger_apis}
        [Yajl::Encoder.encode(o)]
      end

      jellyfish.get %r{\A/swagger/(?<name>.+)\Z} do |match|
        name = "/#{match[:name]}"
        basePath = "#{request.scheme}://#{request.host_with_port}"
        apis = jellyfish_apis[name].map{ |nickname, operations|
          {'path' => nickname, 'operations' => operations}
        }

        o = {'apiVersion' => '1.0.0', 'swaggerVersion' => '1.2',
             'basePath' => basePath, 'resourcePath' => name,
             'produces' => ['application/json'], 'apis' => apis}
        [Yajl::Encoder.encode(o)]
      end
    end
  end
end
