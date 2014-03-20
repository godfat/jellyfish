
require 'jellyfish/test'
require 'muack'

Bacon::Context.include Muack::API

describe Jellyfish do
  after do
    Muack.verify
  end

  app = Class.new{
    include Jellyfish
    handle(StandardError){ |env| 0 }
  }.new

  exp = RuntimeError.new

  should "no RuntimeError: can't add a new key into hash during iteration" do
    # make static ancestors so that we could stub it
    ancestors = RuntimeError.ancestors
    stub(RuntimeError).ancestors{ancestors}
    flip = true
    stub(ancestors).index(anything).peek_return do |i|
      if flip
        flip = false
        sleep 0.0001
      end
      i
    end

    2.times.map{
      Thread.new do
        app.send(:best_handler, exp).call({}).should.eq 0
      end
    }.each(&:join)

    flip.should.eq false
  end
end
