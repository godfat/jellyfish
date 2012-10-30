
require 'jellyfish'
require 'rack/request'

require 'new_relic/agent/instrumentation/controller_instrumentation'

module Jellyfish
  module NewRelic
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def block_call argument, block
      path = if argument.respond_to?(:regexp)
               argument.regexp
             else
               argument
             end.to_s[1..-1]
      name = "#{env['REQUEST_METHOD']} #{path}"
        # magic category: NewRelic::MetricParser::WebTransaction::Jellyfish
      perform_action_with_newrelic_trace(:category => 'Controller/Jellyfish',
                                         :path     => path                  ,
                                         :name     => name                  ,
                                         :request  => request               ,
                                         :params   => request.params){super}
    end
  end
end

module NewRelic::MetricParser::WebTransaction::Jellyfish
  include NewRelic::MetricParser::WebTransaction::Pattern
  def is_web_transaction?;        true; end
  def category           ; 'Jellyfish'; end
end
