
require 'jellyfish/urlmap'

module Jellyfish
  class Builder
    def self.app app=nil, to=nil, &block
      new(app, &block).to_app(to)
    end

    def initialize app=nil, &block
      @use, @map, @run, @warmup = [], nil, app, nil
      instance_eval(&block) if block_given?
    end

    def use middleware, *args, &block
      if @map
        current_map, @map = @map, nil
        @use.unshift(lambda{ |app| generate_map(current_map, app) })
      end
      @use.unshift(lambda{ |app| middleware.new(app, *args, &block) })
    end

    def run app
      @run = app
    end

    def warmup lam=nil, &block
      @warmup = lam || block
    end

    def map path, to: nil, &block
      (@map ||= {})[path] = [block, to]
    end

    def rewrite rules, &block
      rules.each do |path, to|
        map(path, :to => to, &block)
      end
    end

    def to_app to=nil
      run = if @map then generate_map(@map, @run) else @run end
      fail 'missing run or map statement' unless run
      app = @use.inject(run){ |a, m| m.call(a) }
      result = if to then Rewrite.new(app, to) else app end
      @warmup.call(result) if @warmup
      result
    end

    private
    def generate_map current_map, app
      mapped = if app then {'' => app} else {} end
      current_map.each do |path, (block, to)|
        mapped[path.chomp('/')] = self.class.app(app, to, &block)
      end
      URLMap.new(mapped)
    end
  end
end
