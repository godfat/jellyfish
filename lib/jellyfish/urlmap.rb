
module Jellyfish
  class URLMap
    def initialize mapped
      keys = mapped.keys
      @no_host = !keys.any?{ |k| k.match?(%r{\Ahttps?://}) }

      string = keys.sort_by{ |k| -k.size }.
        map{ |k| build_regexp(k) }.
        join('|')

      @mapped = mapped
      @routes = Regexp.new("\\A(?:#{string})(?:/|\\z)", 'i', 'n')
    end

    def call env
      path_info = env['PATH_INFO']

      if @no_host
        if matched = @routes.match(path_info)
          cut_path = matched.to_s.chomp('/')
          script_name = path = cut_path.squeeze('/')
        end
      else
        host = env['HTTP_HOST'].to_s
        if matched = @routes.match("#{host}/#{path_info}")
          cut_path = matched.to_s[host.size + 1..-1].chomp('/')
          script_name = cut_path.squeeze('/')

          path =
            if matched[1]
              "http://#{matched.to_s.squeeze('/').chomp('/')}"
            else
              script_name
            end
        end
      end

      if app = @mapped[path]
        app.call(env.merge('PATH_INFO' => path_info[cut_path.size..-1],
                           'SCRIPT_NAME' => env['SCRIPT_NAME'] + script_name))
      else
        [404, {}, []]
      end
    end

    private

    def build_regexp path
      if @no_host
        regexp_path(path)
      elsif matched = path.match(%r{\Ahttps?://([^/]+)(/?.*)})
        # We only need to know if we're matching against a host,
        # therefore just an empty group is sufficient.
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
