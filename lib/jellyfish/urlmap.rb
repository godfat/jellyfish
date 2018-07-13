
module Jellyfish
  class URLMap
    def initialize mapped
      string = mapped.keys.sort_by{ |k| -k.size }.
        map{ |k| build_regexp(k) }.
        join('|')

      p @mapped = mapped
      p @routes = Regexp.new("\\A(?:#{string})(?:/|\\z)", 'i', 'n')
    end

    def call env
      p path_info = env['PATH_INFO']
      host      = env['HTTP_HOST'].to_s
      if p m   = @routes.match("#{host}/#{path_info}")
        if m[1]
          matched = m.to_s
        else
          matched = m.to_s[host.size + 1 .. -1]
        end
        info = m.to_s[host.size + 1 .. -1].chomp('/')
        script_name = info.squeeze('/')
      end
      squeezed  = matched && matched.squeeze('/').chomp('/')
      search =
        if m && m[1]
          "http://#{squeezed}"
        else
          squeezed
        end

      if app = @mapped[search]
        app.call(env.merge('PATH_INFO' => path_info[info.size..-1] || '',
                           'SCRIPT_NAME' => env['SCRIPT_NAME'] + script_name))
      else
        [404, {}, []]
      end
    end

    private

    def build_regexp path
      if matched = path.match(%r{\Ahttps?://([^/]+)(/.*)})
        "(#{matched[1]})/#{regexp_path(matched[2])}"
      else
        "[^/]*/#{regexp_path(path)}"
      end
    end

    def regexp_path path
      Regexp.escape(path).gsub('/', '/+')
    end
  end
end
