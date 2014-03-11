
require 'jellyfish/test'

describe Jellyfish do
  behaves_like :jellyfish

  app = Class.new{
    include Jellyfish
    get
  }.new

  should 'match wildcard' do
    get('/a', app).should.eq [200, {}, ['']]
    get('/b', app).should.eq [200, {}, ['']]
  end
end
