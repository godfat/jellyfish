# frozen_string_literal: true

module Jellyfish
  class Rewrite < Struct.new(:app, :from, :to)
    def call env
      app.call(env.merge(
        'SCRIPT_NAME' => delete_suffix(env['SCRIPT_NAME'], from),
        'PATH_INFO' => "#{to}#{env['PATH_INFO']}"))
    end

    if ''.respond_to?(:delete_suffix)
      def delete_suffix str, suffix
        str.delete_suffix(suffix)
      end
    else
      def delete_suffix str, suffix
        str.sub(/#{Regexp.escape(suffix)}\z/, '')
      end
    end
  end
end
