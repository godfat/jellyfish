
require 'jellyfish/test'
require 'muack'

include Muack::API

describe Jellyfish do
  behaves_like :jellyfish

  after do
    Muack.verify
  end

  app = Class.new{
    include Jellyfish
    get('/log')      { log('hi') }
    get('/log_error'){
      log_error(stub(RuntimeError.new).backtrace{ ['backtrace'] }.object)
    }
    def self.name
      'Name'
    end
  }.new

  def mock_log
    log = []
    mock(log).puts(is_a(String)){ |msg| log << msg }
    log
  end

  should "log to env['rack.errors']" do
    log = mock_log
    get('/log', app, 'rack.errors' => log)
    log.should.eq ['[Name] hi']
  end

  should "log_error to env['rack.errors']" do
    log = mock_log
    get('/log_error', app, 'rack.errors' => log)
    log.should.eq ['[Name] #<RuntimeError: RuntimeError> ["backtrace"]']
  end
end
