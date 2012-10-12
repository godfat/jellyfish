
module Jellyfish
  autoload :VERSION, 'jellyfish/version'

  REQUEST_METHOD = 'REQUEST_METHOD'
  PATH_INFO      = 'PATH_INFO'
  LOCATION       = 'Location'
  RACK_ERRORS    = 'rack.errors'

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
    def headers       ; super.merge(LOCATION => url)           ; end
    def body          ; super.map{ |b| b.gsub('VAR_URL', url) }; end
  end

  # -----------------------------------------------------------------

  class Controller
    include Jellyfish
    attr_reader   :routes, :env
    def initialize routes
      @routes = routes
    end

    def call env
      @env = env
      match, block = dispatch
      ret = instance_exec(match, &block)
      body ret if body.nil? # prefer explicitly set values
      [status || 200, headers || {}, body]
    end

    def forward  ; raise(NotFound.new)  ; end
    def found url; raise(Found.new(url)); end
    alias_method :redirect, :found

    def path_info     ; env[PATH_INFO]      || '/'  ; end
    def request_method; env[REQUEST_METHOD] || 'GET'; end

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
        case route
        when Regexp
          match = route.match(path_info)
          break match, block if match
        when String
          break route, block if route == path_info
        end
      } || raise(NotFound.new)
    end
  end

  # -----------------------------------------------------------------

  module DSL
    def handlers; @handlers ||= {}; end
    def routes  ; @routes   ||= {}; end

    def handle_exceptions value=nil
      if value.nil?
        @handle_exceptions ||= true
      else
        @handle_exceptions   = value
      end
    end

    def handle exception, &block; (handlers[exception] ||= []) << block; end

    %w[options get head post put delete patch].each do |method|
      module_eval <<-RUBY
        def #{method} route, &block
          (routes['#{method}'] ||= []) << [route, block]
        end
      RUBY
    end
  end

  # -----------------------------------------------------------------

  def initialize app=nil; @app = app; end

  def call env
    Controller.new(self.class.routes).call(env)
  rescue NotFound => r # forward
    if app
      protect(env){ app.call(env) }
    else
      handle_respond(r)
    end
  rescue Respond => r
    handle_respond(r)
  rescue Exception => e
    handle_exception(e, env[RACK_ERRORS])
  end

  def protect env
    yield
  rescue Respond => r
    handle_respond(r)
  rescue Exception => e
    handle_exception(e, env[RACK_ERRORS])
  end

  private
  def handle_respond r
    raise r unless self.class.handle_exceptions
    respond(r)
  end

  def handle_exception e, stderr
    raise e unless self.class.handle_exceptions
    log_error(e, stderr)
    respond(InternalError.new)
  end

  def respond e
    [e.status, e.headers, e.body]
  end

  def log_error e, stderr
    return unless stderr
    stderr.puts("[#{self.class.name}] #{e.inspect} #{e.backtrace}")
  end

  # -----------------------------------------------------------------

  def self.included mod
    mod.__send__(:extend, DSL)
    mod.__send__(:attr_reader, :app)
  end

  # -----------------------------------------------------------------

  module_function
  def public_root
    "#{File.dirname(__FILE__)}/jellyfish/public"
  end
end
