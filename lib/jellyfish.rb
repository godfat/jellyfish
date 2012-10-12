
module Jellyfish
  autoload :VERSION, 'jellyfish/version'

  REQUEST_METHOD = 'REQUEST_METHOD'
  PATH_INFO      = 'PATH_INFO'
  HOST           = 'HTTP_HOST'
  RACK_ERRORS    = 'rack.errors'
  RACK_SCHEME    = 'rack.url_scheme'

  # -----------------------------------------------------------------

  class Respond < RuntimeError
    def headers
      @headers ||= {'Content-Type' => 'text/html'}
    end

    def body
      @body ||= [File.read("#{Jellyfish.public_root}/#{status}.html")]
    end
  end

  class NotFound      < Respond; def status; 404; end; end
  class InternalError < Respond; def status; 500; end; end
  class Found         < Respond
    attr_reader :url
    def initialize url; @url = url                             ; end
    def status        ; 302                                    ; end
    def headers       ; super.merge('Location' => url)         ; end
    def body          ; super.map{ |b| b.gsub('VAR_URL', url) }; end
  end

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
      body ret if body.nil?
      # prefer explicitly set values
      [status || 200, headers || {}, body]

    rescue Respond   => r
      raise r if raise_exceptions
      respond(r)

    rescue Exception => e
      raise e if raise_exceptions
      log_error(e)
      respond(InternalError.new)
    end

    def found url; raise Found.new(url); end
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

    def respond e
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
