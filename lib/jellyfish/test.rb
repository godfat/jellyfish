
require 'pork/auto'
require 'muack'
require 'jellyfish'
require 'rack'

Pork::Suite.include(Muack::API)

copy :jellyfish do
  module_eval(%w[options get head post put delete patch].map{ |method|
    <<-RUBY
      def #{method} path='/', a=app, env={}
        File.open(File::NULL) do |input|
          a.call({'PATH_INFO'      => path              ,
                  'REQUEST_METHOD' => '#{method}'.upcase,
                  'SCRIPT_NAME'    => ''                ,
                  'rack.input'     => input             ,
                  'rack.url_scheme'=> 'http'            ,
                  'SERVER_NAME'    => 'localhost'       ,
                  'SERVER_PORT'    => '8080'}.merge(env))
        end
      end
    RUBY
  }.join("\n"))
end

copy :stringio do
  def new_stringio
    sock = StringIO.new
    sock.set_encoding('ASCII-8BIT')
    sock
  end
end
