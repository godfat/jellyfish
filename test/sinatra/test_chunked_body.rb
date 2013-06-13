
require 'jellyfish/test'

# stolen from sinatra
describe 'Sinatra streaming_test.rb' do
  behaves_like :jellyfish

  should 'return the concatinated body' do
    app = Class.new{
      include Jellyfish
      get '/' do
        Jellyfish::ChunkedBody.new{ |out|
          out['Hello']
          out[' ']
          out['World!']
        }
      end
    }.new
    _, _, body = get('/', app)
    body.to_a.join.should.eq 'Hello World!'
  end

  should 'postpone body generation' do
    stream = Jellyfish::ChunkedBody.new{ |out|
      10.times{ |i| out[i] }
    }

    stream.each.with_index do |s, i|
      s.should.eq i
    end
  end

  should 'give access to route specific params' do
    app = Class.new{
      include Jellyfish
      get(%r{/(?<name>\w+)}){ |m|
        Jellyfish::ChunkedBody.new{ |o| o[m[:name]] }
      }
    }.new
    _, _, body = get('/foo', app)
    body.to_a.join.should.eq 'foo'
  end
end
