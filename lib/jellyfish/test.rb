
require 'pork/auto'
require 'muack'
require 'jellyfish'
require 'rack'

Pork::Executor.__send__(:include, Muack::API)

copy :jellyfish do
  %w[options get head post put delete patch].each do |method|
    module_eval <<-RUBY
      def #{method} path='/', app=app, env={}
        File.open(File::NULL) do |input|
          app.call({'PATH_INFO'      => path              ,
                    'REQUEST_METHOD' => '#{method}'.upcase,
                    'SCRIPT_NAME'    => ''                ,
                    'rack.input'     => input             ,
                    'rack.url_scheme'=> 'https'           ,
                    'SERVER_NAME'    => 'localhost'       ,
                    'SERVER_PORT'    => '8080'}.merge(env))
        end
      end
    RUBY
  end
end
