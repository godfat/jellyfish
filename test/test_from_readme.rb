
require 'jellyfish/test'
require 'uri'

describe 'from README.md' do
  after do
    [:Tank, :Heater, :Protector].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
  end

  readme = File.read(
             "#{File.dirname(File.expand_path(__FILE__))}/../README.md")
  codes  = readme.scan(
    /### ([^\n]+).+?``` ruby\n(.+?)\n```\n\n<!---(.+?)-->/m)

  codes.each.with_index do |(title, code, test), index|
    if title =~ /NewRelic/i
      warn "Skip NewRelic Test" unless Bacon.kind_of?(Bacon::TestUnitOutput)
      next
    end

    should "pass from README.md #%02d #{title}" % index do
      method_path, expect = test.strip.split("\n", 2)
      method, path        = method_path.split(' ')
      uri                 = URI.parse(path)
      pinfo, query        = uri.path, uri.query

      status, headers, body = File.open(File::NULL) do |input|
        Rack::Builder.new{ eval(code) }.call(
          'REQUEST_METHOD' => method, 'PATH_INFO'  => pinfo,
          'QUERY_STRING'   => query , 'rack.input' => input)
      end

      body.extend(Enumerable)
      [status, headers, body.to_a].should.eq eval(expect, binding, __FILE__)
    end
  end
end
