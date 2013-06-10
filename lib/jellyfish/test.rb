
require 'bacon'
require 'rack'
require 'jellyfish'

Bacon.summary_on_exit

shared :jellyfish do
  %w[options get head post put delete patch].each do |method|
    instance_eval <<-RUBY
      def #{method} path='/', app=app, query=''
        File.open(File::NULL) do |input|
          app.call('PATH_INFO'      => path              ,
                   'REQUEST_METHOD' => '#{method}'.upcase,
                   'QUERY_STRING'   => query             ,
                   'rack.input'     => input             )
        end
      end
    RUBY
  end
end

module Kernel
  def eq? rhs
    self == rhs
  end
end
