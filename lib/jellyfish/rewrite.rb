
module Jellyfish
  class Rewrite < Struct.new(:app, :to)
    def call env
      app.call(env.merge('PATH_INFO' => "#{env['PATH_INFO']}#{to}"))
    end
  end
end
