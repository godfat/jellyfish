
require 'jellyfish/json'

module Jellyfish
  class Swagger
    include Jellyfish
    controller_include Jellyfish::NormalizedPath, Module.new{
      def dispatch
        headers_merge 'Content-Type' => 'application/json; charset=utf-8'
        super
      end
    }

    get '/' do
      [Jellyfish::Json.encode(
        :swaggerVersion => '1.2'                       ,
        :info           => jellyfish.swagger_info      ,
        :apiVersion     => jellyfish.swagger_apiVersion,
        :apis           => jellyfish.swagger_apis      )]
    end

    get %r{\A/(?<name>.+)\Z} do |match|
      basePath =
      "#{request.scheme}://#{request.host_with_port}#{jellyfish.path_prefix}"
      name     = "/#{match[:name]}"
      apis     = jellyfish.jellyfish_apis[name].map{ |path, operations|
        {:path => path, :operations => operations}
      }

      [Jellyfish::Json.encode(
        :swaggerVersion => '1.2'                       ,
        :basePath       => basePath                    ,
        :resourcePath   => name                        ,
        :apiVersion     => jellyfish.swagger_apiVersion,
        :apis           => apis                        )]
    end

    # The application should define the API description.
    def swagger_info
      if app.respond_to?(:info)
        app.info
      else
        {}
      end
    end

    # The application should define the API version.
    def swagger_apiVersion
      if app.respond_to?(:swagger_apiVersion)
        app.swagger_apiVersion
      else
        '0.1.0'
      end
    end

    def swagger_apis
      @swagger_apis ||= jellyfish_apis.keys.map do |name|
        {:path => name}
      end
    end

    attr_reader :jellys, :path_prefix
    def initialize path_prefix='', *apps
      super(apps.first)
      @jellys      = apps
      @path_prefix = path_prefix
    end

    def jellyfish_apis
      @jellyfish_apis ||= jellys.flat_map{ |j|
        j.routes.flat_map{ |meth, routes|
          routes.map{ |(path, _, meta)|
            meta.merge(operation(meth, path, meta))
          }
        }
      }.group_by{ |api| api[:path] }.
        inject(Hash.new{[]}){ |r, (path, operations)|
          r[path] = operations.group_by{ |op| op[:nickname] }
          r
        }
    end

    private
    def operation meth, path, meta
      if path.respond_to?(:source)
        nick = nickname(path)
        {:path       => swagger_path(nick)          ,
         :method     => meth.to_s.upcase            ,
         :nickname   => nick                        ,
         :summary    => meta[:summary]              ,
         :notes      => notes(meta)                 ,
         :parameters => path_parameters(path, meta) }
      else
        {:path       => swagger_path(path)          ,
         :method     => meth.to_s.upcase            ,
         :nickname   => path                        ,
         :summary    => meta[:summary]              ,
         :notes      => notes(meta)                 ,
         :parameters => query_parameters(meta)      }
      end
    end

    def swagger_path nickname
      nickname[%r{^/[^/]*}]
    end

    def nickname path
      if path.respond_to?(:source)
        path.source.gsub(param_pattern, '{\1}').gsub(/\\\w+|[\^\$]/, '')
      else
        path.to_s
      end
    end

    def notes meta
      if meta[:notes]
        "#{meta[:summary]}<br>#{meta[:notes]}"
      else
        meta[:summary]
      end
    end

    def path_parameters path, meta
      Hash[path.source.scan(param_pattern)].map{ |name, pattern|
        path_param(name, pattern, meta)
      }
    end

    def query_parameters meta
      if meta[:parameters]
        meta[:parameters].map{ |(name, param)|
          param.merge(:name      => name.to_s,
                      :type      => param[:type] || 'string',
                      :required  => !!param[:required],
                      :paramType => param[:paramType] || 'query')
        }
      else
        []
      end
    end

    def path_param name, pattern, meta
      param = (meta[:parameters] || {})[name.to_sym] || {}
      param.merge(:name      => name                               ,
                  :type      => param[:type] || param_type(pattern),
                  :required  => true                               ,
                  :paramType => 'path'                             )
    end

    def param_type pattern
      if pattern.start_with?('\\d')
        if pattern.include?('.')
          'number'
        else
          'integer'
        end
      else
        'string'
      end
    end

    def param_pattern
      /\(\?<(\w+)>([^\)]+)\)/
    end
  end
end
