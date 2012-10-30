
module Jellyfish
  autoload :VERSION , 'jellyfish/version'
  autoload :Sinatra , 'jellyfish/sinatra'
  autoload :NewRelic, 'jellyfish/newrelic'

  class Response < RuntimeError
    def headers
      @headers ||= {'Content-Type' => 'text/html'}
    end

    def body
      @body ||= [File.read("#{Jellyfish.public_root}/#{status}.html")]
    end
  end

  class InternalError < Response; def status; 500; end; end
  class NotFound      < Response; def status; 404; end; end
  class Found         < Response # this would be raised in redirect
    attr_reader :url
    def initialize url; @url = url                             ; end
    def status        ; 302                                    ; end
    def headers       ; super.merge('Location' => url)         ; end
    def body          ; super.map{ |b| b.gsub('VAR_URL', url) }; end
  end

  # -----------------------------------------------------------------

  class Controller
    module Call
      def call env
        @env = env
        block_call(*dispatch)
      end

      def block_call argument, block
        ret = instance_exec(argument, &block)
        body ret if body.nil? # prefer explicitly set values
        body ''  if body.nil? # at least give an empty string
        [status || 200, headers || {}, body]
      rescue LocalJumpError
        jellyfish.log("Use `next' if you're trying to `return' or" \
                      " `break' from the block.", env['rack.errors'])
        raise
      end
    end
    include Call

    attr_reader :routes, :jellyfish, :env
    def initialize routes, jellyfish
      @routes, @jellyfish = routes, jellyfish
      @status, @headers, @body = nil
    end

    def request  ; @request ||= Rack::Request.new(env); end
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
    ctrl = controller.new(self.class.routes, self)
    ctrl.call(env)
  rescue NotFound => e # forward
    if app
      begin
        app.call(env)
      rescue Exception => e
        handle(ctrl, e, env['rack.errors'])
      end
    else
      handle(ctrl, e)
    end
  rescue Exception => e
    handle(ctrl, e, env['rack.errors'])
  end

  def log_error e, stderr
    return unless stderr
    stderr.puts("[#{self.class.name}] #{e.inspect} #{e.backtrace}")
  end

  def log msg, stderr
    return unless stderr
    stderr.puts("[#{self.class.name}] #{msg}")
  end

  private
  def handle ctrl, e, stderr=nil
    handler = self.class.handlers.find{ |klass, block|
      break block if e.kind_of?(klass)
    }
    if handler
      ctrl.block_call(e, handler)
    elsif !self.class.handle_exceptions
      raise e
    elsif e.kind_of?(Response) # InternalError ends up here if no handlers
      [e.status, e.headers, e.body]
    else # fallback and see if there's any InternalError handler
      log_error(e, stderr)
      handle(ctrl, InternalError.new)
    end
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
