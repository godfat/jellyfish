
module Jellyfish
  REQUEST_METHOD = 'REQUEST_METHOD'
  PATH_INFO      = 'PATH_INFO'

  class Error < RuntimeError
    def headers
      {'Content-Type' => 'text/html'}
    end

    def body
      @body ||= [File.read("#{root}/#{status}.html")]
    end

    def root
      "#{File.dirname(__FILE__)}/jellyfish/public"
    end
  end

  class NotFound      < Error; def status; 404; end; end
  class InternalError < Error; def status; 500; end; end

  class Controller
    attr_reader :routes
    def initialize routes
      @routes = routes
    end

    def call env
      match, block = dispatch(env)
      body = instance_exec(match, &block)
      [200, {}, [body]]

    rescue Error     => e
      [e.status, e.headers, e.body]

    rescue Exception => e
      p e
      # TODO
    end

    def actions env
      routes[request_method(env).downcase] || raise(Jellyfish::NotFound.new)
    end

    def path_info      env; env[PATH_INFO]      || '/'  ; end
    def request_method env; env[REQUEST_METHOD] || 'GET'; end

    def dispatch env
      actions(env).find{ |(route, block)|
        match = route.match(path_info(env))
        break match, block if match
      } || raise(Jellyfish::NotFound.new)
    end
  end

  def initialize; @routes   = {}; end
  def routes    ; @routes ||= {}; end

  def call env  ; Controller.new(routes).call(env); end

  %w[options get head post put delete patch].each do |method|
    module_eval <<-RUBY
      def #{method} route, &block
        (routes['#{method}'] ||= []) << [route, block]
      end
    RUBY
  end
end
