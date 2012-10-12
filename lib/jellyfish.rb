
module Jellyfish
  autoload :VERSION, 'jellyfish/version'

  REQUEST_METHOD = 'REQUEST_METHOD'
  PATH_INFO      = 'PATH_INFO'
  HOST           = 'HTTP_HOST'
  RACK_ERRORS    = 'rack.errors'
  RACK_SCHEME    = 'rack.url_scheme'

  # -----------------------------------------------------------------

  class Error < RuntimeError
    def headers
      {'Content-Type' => 'text/html'}
    end

    def body
      @body ||= [File.read("#{Jellyfish.public_root}/#{status}.html")]
    end
  end

  class NotFound      < Error; def status; 404; end; end
  class InternalError < Error; def status; 500; end; end

  # -----------------------------------------------------------------

  class Controller
    include Jellyfish
    attr_reader   :routes, :env
    attr_accessor :raise_exceptions
    def initialize routes, raise_exceptions
      @routes, @raise_exceptions = routes, raise_exceptions
    end

    def call env
      @env = env
      match, block = dispatch
      ret = instance_exec(match, &block)
      # prefer explicitly set values
      [status || 200, headers || {}, body || [ret]]

    rescue Error     => e
      raise e if raise_exceptions
      call_error(e)

    rescue Exception => e
      raise e if raise_exceptions
      log_error(e)
      call_error(InternalError.new)
    end

    def found url
      status 302
      headers_merge 'Location' => url
      body File.read("#{public_root}/#{status}.html").gsub('VAR_URL', url)
    end
    alias_method :redirect, :found

    def path_info     ; env[PATH_INFO]      || '/'  ; end
    def request_method; env[REQUEST_METHOD] || 'GET'; end

    def log_error e, stderr=env[RACK_ERRORS]
      return unless stderr
      stderr.puts("[#{self.class.name}] #{e.inspect} #{e.backtrace}")
    end

    %w[status headers].each do |field|
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

    def body value=nil
      if value.nil?
        @body
      elsif value.respond_to?(:each) # per rack SPEC
        @body = value
      else
        @body = [value]
      end
    end

    def headers_merge value
      if headers.nil?
        headers(value)
      else
        headers(headers.merge(value))
      end
    end



    private
    def actions
      routes[request_method.downcase] || raise(NotFound.new)
    end

    def dispatch
      actions.find{ |(route, block)|
        match = route.match(path_info)
        break match, block if match
      } || raise(NotFound.new)
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

  # -----------------------------------------------------------------

  module_function
  def public_root
    "#{File.dirname(__FILE__)}/jellyfish/public"
  end
end
