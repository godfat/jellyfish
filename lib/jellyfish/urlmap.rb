
module Jellyfish
  class URLMap
    def initialize mapped
      string = mapped.keys.sort_by{ |k| -k.size }.
        map{ |k| Regexp.escape(k).gsub('/', '/+') }.
        join('|')

      @mapped = mapped
      @routes = Regexp.new("\\A(?:#{string})(?:/|\\z)", 'i', 'n')
    end

    def call env
      path_info = env['PATH_INFO']
      matched   = @routes.match(path_info).to_s.chomp('/')
      squeezed  = matched.squeeze('/')

      if app = @mapped[squeezed]
        app.call(env.merge('PATH_INFO' => path_info[matched.size..-1],
                           'SCRIPT_NAME' => env['SCRIPT_NAME'] + squeezed))
      else
        [404, {}, []]
      end
    end
  end
end
