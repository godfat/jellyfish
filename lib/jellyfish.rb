# frozen_string_literal: true

module Jellyfish
  autoload :VERSION , 'jellyfish/version'

  autoload :NormalizedParams, 'jellyfish/normalized_params'
  autoload :NormalizedPath  , 'jellyfish/normalized_path'

  autoload :Builder    , 'jellyfish/builder'
  autoload :Rewrite    , 'jellyfish/rewrite'
  autoload :ChunkedBody, 'jellyfish/chunked_body'
  autoload :WebSocket  , 'jellyfish/websocket'

  Cascade  = Object.new
  GetValue = Object.new

  class Response < RuntimeError
    def headers
      @headers ||= {'content-type' => 'text/html'}
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
    def headers       ; super.merge('location' => url)         ; end
    def body          ; super.map{ |b| b.gsub('VAR_URL', url) }; end
  end

  # -----------------------------------------------------------------

  class Controller
    attr_reader :routes, :jellyfish, :env
    def initialize routes, jellyfish
      @routes, @jellyfish = routes, jellyfish
      @status, @headers, @body = nil
    end

    def call env
      @env = env
      block_call(*dispatch)
    end

    def block_call argument, block
      val = instance_exec(argument, &block)
      [status || 200, headers || {}, body || rack_body(val || '')]
    rescue LocalJumpError
      log("Use `next' if you're trying to `return' or `break' from a block.")
      raise
    end

    def log     message; jellyfish.log(    message, env); end
    def log_error error; jellyfish.log_error(error, env); end
    def request   ; @request ||= Rack::Request.new(env); end
    def halt *args; throw(:halt, *args)                ; end
    def cascade   ;  halt(Jellyfish::Cascade)          ; end
    def not_found ;  halt(Jellyfish::NotFound.new)     ; end
    def found  url;  halt(Jellyfish::   Found.new(url)); end
    alias_method :redirect, :found

    def path_info     ; env['PATH_INFO']      || '/'  ; end
    def request_method; env['REQUEST_METHOD'] || 'GET'; end

    %w[status headers].each do |field|
      module_eval <<-RUBY
        def #{field} value=GetValue
          if value == GetValue
            @#{field}
          else
            @#{field} = value
          end
        end
      RUBY
    end

    def body value=GetValue
      if value == GetValue
        @body
      elsif value.nil?
        @body = value
      else
        @body = rack_body(value)
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
      routes[request_method.downcase] || action_missing
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
      } || action_missing
    end

    def action_missing
      if jellyfish.app then cascade else not_found end
    end

    def rack_body v
      if v.respond_to?(:each) || v.respond_to?(:to_path) then v else [v] end
    end
  end

  # -----------------------------------------------------------------

  module DSL
    def routes  ; @routes   ||= {}; end
    def handlers; @handlers ||= {}; end
    def handle *exceptions, &block
      exceptions.each{ |exp| handlers[exp] = block }
    end
    def handle_exceptions value=GetValue
      if value == GetValue
        @handle_exceptions
      else
        @handle_exceptions = value
      end
    end

    def controller_include *value
      (@controller_include ||= []).push(*value)
    end

    def controller value=GetValue
      if value == GetValue
        @controller ||= controller_inject(
          const_set(:Controller, Class.new(Controller)))
      else
        @controller   = controller_inject(value)
      end
    end

    def controller_inject value
      controller_include.
        inject(value){ |ctrl, mod| ctrl.__send__(:include, mod) }
    end

    %w[options get head post put delete patch].each do |method|
      define_method(method) do |route=//, meta={}, &block|
        define(method, route, meta, &block)
      end
    end

    def define(method, route=//, meta={}, &block)
      raise TypeError.new("Route #{route} should respond to :match") \
        unless route.respond_to?(:match)

      (routes[method.to_s] ||= []) << [route, block || lambda{|_|}, meta]
    end

    def inherited sub
      sub.handle_exceptions(handle_exceptions)
      sub.controller_include(*controller_include)
      [:handlers, :routes].each{ |m|
        val = __send__(m).inject({}){ |r, (k, v)| r[k] = v.dup; r }
        sub.__send__(m).replace(val) # dup the routing arrays
      }
    end
  end

  # -----------------------------------------------------------------

  def initialize app=nil; @app = app; end

  def call env
    ctrl = self.class.controller.new(self.class.routes, self)
    case res = catch(:halt){ ctrl.call(env) }
    when Cascade
      cascade(ctrl, env)
    when Response
      handle(ctrl, res, env)
    when Array
      res
    when NilClass # make sure we return rack triple
      ctrl.block_call(nil, lambda{|_|_})
    else
      raise TypeError.new("Expect the response to be a Jellyfish::Response" \
        " or Rack triple (Array), but got: #{res.inspect}")
    end
  rescue => error
    handle(ctrl, error, env)
  end

  def log_error error, env
    env['rack.errors']&.
      puts("[#{self.class.name}] #{error.inspect}" \
           " for #{env['PATH_INFO'] || '/'} #{error.backtrace}")
  end

  def log msg, env
    env['rack.errors']&.
      puts("[#{self.class.name}] #{msg}")
  end

  private
  def cascade ctrl, env
    app.call(env)
  rescue => error
    handle(ctrl, error, env)
  end

  def handle ctrl, error, env
    if handler = best_handler(error)
      ctrl.block_call(error, handler)
    elsif !self.class.handle_exceptions
      raise error
    elsif error.kind_of?(Response) # InternalError ends up here if no handlers
      [error.status, error.headers, error.body]
    else # fallback and see if there's any InternalError handler
      log_error(error, env)
      handle(ctrl, InternalError.new, env)
    end
  end

  def best_handler error
    handlers = self.class.handlers
    if handlers.key?(error.class)
      handlers[error.class]
    else # or find the nearest match and cache it
      ancestors = error.class.ancestors
      handlers[error.class] = handlers.dup. # thread safe iteration
        inject([nil, Float::INFINITY]){ |(handler, val), (klass, block)|
          idx = ancestors.index(klass) || Float::INFINITY # lower is better
          if idx < val then [block, idx] else [handler, val] end }.first
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
