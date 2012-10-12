
module Jellyfish
  autoload :VERSION, 'jellyfish/version'

  REQUEST_METHOD = 'REQUEST_METHOD'
  PATH_INFO      = 'PATH_INFO'
  RACK_ERRORS    = 'rack.errors'

  # -----------------------------------------------------------------

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

  # -----------------------------------------------------------------

  class Controller
    attr_reader   :routes
    attr_accessor :raise_exceptions
    def initialize routes, raise_exceptions
      @routes, @raise_exceptions = routes, raise_exceptions
    end

    def call env
      match, block = dispatch(env)
      ret = instance_exec(match, &block)
      # prefer explicitly set values
      [status || 200, headers || {}, body || [ret]]

    rescue Error     => e
      raise e if raise_exceptions
      call_error(e)

    rescue Exception => e
      raise e if raise_exceptions
      log_error(e, env[RACK_ERRORS]) if env[RACK_ERRORS]
      call_error(Jellyfish::InternalError.new)
    end

    def path_info      env; env[PATH_INFO]      || '/'  ; end
    def request_method env; env[REQUEST_METHOD] || 'GET'; end

    def log_error e, stderr
      stderr.puts("[#{self.class.name}] #{e.inspect} #{e.backtrace}")
    end

    %w[status headers body].each do |field|
      module_eval <<-RUBY
        def #{field} value=nil
          if value.nil?
            @#{field}
          else
            @#{field} = value
          end
        end
      RUBY
    end



    private
    def actions env
      routes[request_method(env).downcase] || raise(Jellyfish::NotFound.new)
    end

    def dispatch env
      actions(env).find{ |(route, block)|
        match = route.match(path_info(env))
        break match, block if match
      } || raise(Jellyfish::NotFound.new)
    end

    def call_error e
      [e.status, e.headers, e.body]
    end
  end

  # -----------------------------------------------------------------

  def initialize; @routes   = {}; end
  def routes    ; @routes ||= {}; end

  def call env  ; Controller.new(routes, raise_exceptions).call(env); end

  def raise_exceptions value=nil
    if value.nil?
      @raise_exceptions || false
    else
      @raise_exceptions = value
    end
  end

  %w[options get head post put delete patch].each do |method|
    module_eval <<-RUBY
      def #{method} route, &block
        (routes['#{method}'] ||= []) << [route, block]
      end
    RUBY
  end
end
