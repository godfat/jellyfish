
module Jellyfish
  class URLMap
    def initialize mapped
      string = mapped.keys.sort_by{ |k| -k.size }.
        map{ |k| build_regexp(k) }.
        join('|')

      @mapped = mapped
      @routes = Regexp.new("\\A(?:#{string})(?:/|\\z)", 'i', 'n')
    end

    def call env
      path_info = env['PATH_INFO']
      host      = env['HTTP_HOST'].to_s
      if m   = @routes.match("#{host}/#{path_info}")
        cut_path = m.to_s[host.size + 1 .. -1].chomp('/')
        script_name = cut_path.squeeze('/')

        search =
          if m[1]
            "http://#{m.to_s.squeeze('/').chomp('/')}"
          else
            script_name
          end
      end

      if app = @mapped[search]
        app.call(env.merge('PATH_INFO' => path_info[cut_path.size..-1],
                           'SCRIPT_NAME' => env['SCRIPT_NAME'] + script_name))
      else
        [404, {}, []]
      end
    end

    private

    def build_regexp path
      if matched = path.match(%r{\Ahttps?://([^/]+)(/.*)})
        "()#{matched[1]}/#{regexp_path(matched[2])}"
      else
        "[^/]*/#{regexp_path(path)}"
      end
    end

    def regexp_path path
      Regexp.escape(path).gsub('/', '/+')
    end
  end
end
