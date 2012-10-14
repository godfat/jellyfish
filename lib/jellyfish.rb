
module Jellyfish
  autoload :VERSION, 'jellyfish/version'
  autoload :Sinatra, 'jellyfish/sinatra'

  # -----------------------------------------------------------------

  class Respond < RuntimeError
    def headers
      @headers ||= {'Content-Type' => 'text/html'}
    end

    def body
      @body ||= [File.read("#{Jellyfish.public_root}/#{status}.html")]
    end
  end

  class InternalError < Respond; def status; 500; end; end
  class NotFound      < Respond; def status; 404; end; end
  class Found         < Respond
    attr_reader :url
    def initialize url; @url = url                             ; end
    def status        ; 302                                    ; end
    def headers       ; super.merge('Location' => url)         ; end
    def body          ; super.map{ |b| b.gsub('VAR_URL', url) }; end
  end

  # -----------------------------------------------------------------

  class Controller
    attr_reader   :routes, :env
    def initialize routes
      @routes = routes
    end

    def call env
      @env = env
      block_call(*dispatch)
    end

    def block_call argument, block
      ret = instance_exec(argument, &block)
      body ret if body.nil? # prefer explicitly set values
      [status || 200, headers || {}, body]
    end

    def forward  ; raise(Jellyfish::NotFound.new)     ; end
    def found url; raise(Jellyfish::   Found.new(url)); end
    alias_method :redirect, :found

    def path_info     ; env['PATH_INFO']      || '/'  ; end
    def request_method; env['REQUEST_METHOD'] || 'GET'; end

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
      routes[request_method.downcase] || raise(Jellyfish::NotFound.new)
    end

    def dispatch
      actions.find{ |(route, block)|
        case route
        when String
          break route, block if route == path_info
        else#Regexp, using else allows you to use custom matcher
          match = route.match(path_info)
          break match, block if match
        end
      } || raise(Jellyfish::NotFound.new)
    end
  end

  # -----------------------------------------------------------------

  module DSL
    def handlers; @handlers ||= {}; end
    def routes  ; @routes   ||= {}; end

    def handle_exceptions value=nil
      if value.nil?
        @handle_exceptions
      else
        @handle_exceptions = value
      end
    end

    def handle exception, &block; handlers[exception] = block; end

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
  def controller        ; Controller; end

  def call env
    ctrl = controller.new(self.class.routes)
    ctrl.call(env)
  rescue NotFound => e # forward
    if app
      protect(ctrl, env){ app.call(env) }
    else
      handle(ctrl, e)
    end
  rescue Exception => e
    handle(ctrl, e, env['rack.errors'])
  end

  def protect ctrl, env
    yield
  rescue Exception => e
    handle(ctrl, e, env['rack.errors'])
  end

  private
  def handle ctrl, e, stderr=nil
    raise e unless self.class.handle_exceptions
    handler = self.class.handlers.find{ |klass, block|
      break block if e.kind_of?(klass)
    }
    if handler
      ctrl.block_call(e, handler)
    elsif e.kind_of?(Respond) # InternalError ends up here if no handlers
      [e.status, e.headers, e.body]
    else # fallback and see if there's any InternalError handler
      log_error(e, stderr)
      handle(ctrl, InternalError.new)
    end
  end

  def log_error e, stderr
    return unless stderr
    stderr.puts("[#{self.class.name}] #{e.inspect} #{e.backtrace}")
  end

  # -----------------------------------------------------------------

  def self.included mod
    mod.__send__(:extend, DSL)
    mod.__send__(:attr_reader, :app)
    mod.handle_exceptions(true)
  end

  # -----------------------------------------------------------------

  module_function
  def public_root
    "#{File.dirname(__FILE__)}/jellyfish/public"
  end
end
