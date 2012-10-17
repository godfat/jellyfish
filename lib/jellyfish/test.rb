
require 'bacon'
require 'rack'
require 'jellyfish'

Bacon.summary_on_exit

shared :jellyfish do
  %w[options get head post put delete patch].each do |method|
    instance_eval <<-RUBY
      def #{method} path='/', app=app
        app.call('PATH_INFO' => path, 'REQUEST_METHOD' => '#{method}'.upcase)
      end
    RUBY
  end
end

module Kernel
  def eq? rhs
    self == rhs
  end
end
