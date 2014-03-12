
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

  should 'accept to_path body' do
    a = Class.new{
      include Jellyfish
      get{ File.open(__FILE__) }
    }.new
    get('/', a).last.to_path.should.eq __FILE__
  end
end
