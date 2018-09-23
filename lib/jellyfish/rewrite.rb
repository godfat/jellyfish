
module Jellyfish
  class Rewrite < Struct.new(:app, :to)
    def call env
      app.call(env.merge('PATH_INFO' => "#{to}#{env['PATH_INFO']}"))
    end
  end
end
