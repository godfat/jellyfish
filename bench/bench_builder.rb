
# Calculating -------------------------------------
#    Jellyfish::URLMap     5.726k i/100ms
#         Rack::URLMap   167.000  i/100ms
# -------------------------------------------------
#    Jellyfish::URLMap     62.397k (± 1.2%) i/s -    314.930k
#         Rack::URLMap      1.702k (± 1.5%) i/s -      8.517k

# Comparison:
#    Jellyfish::URLMap:    62397.3 i/s
#         Rack::URLMap:     1702.0 i/s - 36.66x slower

require 'jellyfish'
require 'rack'

require 'benchmark/ips'

num = 1000
app = lambda do |_|
  ok = [200, {}, []]
  rn = lambda{ |_| ok }

  (0...num).each do |i|
    map "/#{i}" do
      run rn
    end
  end
end

jelly = Jellyfish::Builder.app(&app)
rack  = Rack::Builder.app(&app)
path_info = 'PATH_INFO'

Benchmark.ips do |x|
  x.report(jelly.class) do
    jelly.call(path_info => rand(num).to_s)
  end

  x.report(rack.class) do
    rack.call(path_info => rand(num).to_s)
  end

  x.compare!
end
