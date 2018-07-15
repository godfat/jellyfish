
require 'uri'

module Jellyfish
  class URLMap
    def initialize mapped_not_chomped
      mapped = transform_keys(mapped_not_chomped){ |k| k.sub(%r{/+\z}, '') }
      keys = mapped.keys
      @no_host = !keys.any?{ |k| match?(k, %r{\Ahttps?://}) }

      string = sort_keys(keys).
        map{ |k| build_regexp(k) }.
        join('|')

      @mapped = mapped
      @routes = %r{\A(?:#{string})(?:/|\z)}
    end

    def call env
      path_info = env['PATH_INFO']

      if @no_host
        if matched = @routes.match(path_info)
          cut_path = matched.to_s.chomp('/')
          script_name = key = cut_path.squeeze('/')
        end
      else
        host = (env['HTTP_HOST'] || env['SERVER_NAME']).to_s.downcase
        if matched = @routes.match("#{host}/#{path_info}")
          cut_path = matched.to_s[host.size + 1..-1].chomp('/')
          script_name = cut_path.squeeze('/')

          key =
            if matched[:host]
              host_with_path =
                if script_name.empty?
                  host
                else
                  File.join(host, script_name)
                end
              "#{env['rack.url_scheme']}://#{host_with_path}"
            else
              script_name
            end
        end
      end

      if app = @mapped[key]
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
        "(?<host>)#{matched[1]}/#{regexp_path(matched[2])}"
      else
        "[^/]*/#{regexp_path(path)}"
      end
    end

    def regexp_path path
      Regexp.escape(path).gsub('/', '/+')
    end

    def transform_keys hash, &block
      if hash.respond_to?(:transform_keys)
        hash.transform_keys(&block)
      else
        hash.inject({}) do |result, (key, value)|
          result[yield(key)] = value
          result
        end
      end
    end

    def match? string, regexp
      if string.respond_to?(:match?)
        string.match?(regexp)
      else
        string =~ regexp
      end
    end

    def sort_keys keys
      keys.sort_by do |k|
        uri = URI.parse(k)

        [-uri.path.to_s.size, -uri.host.to_s.size]
      end
    end
  end
end
