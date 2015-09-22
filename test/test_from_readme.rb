
require 'jellyfish/test'
require 'uri'
require 'stringio'

describe 'from README.md' do
  after do
    [:Tank, :Heater, :Protector].each do |const|
      Object.send(:remove_const, const) if Object.const_defined?(const)
    end
    Muack.verify
  end

  readme = File.read(
             "#{File.dirname(File.expand_path(__FILE__))}/../README.md")
  codes  = readme.scan(
    /### ([^\n]+).+?``` ruby\n(.+?)\n```\n\n<!---(.+?)-->/m)

  codes.each.with_index do |(title, code, test), index|
    next if title =~ /NewRelic/i

    would "pass from README.md #%02d #{title}" % index do
      app = Rack::Builder.app{ eval(code) }

      test.split("\n\n").each do |t|
        method_path, expect = t.strip.split("\n", 2)
        method, path        = method_path.split(' ')
        uri                 = URI.parse(path)
        pinfo, query        = uri.path, uri.query

        sock = nil
        status, headers, body = File.open(File::NULL) do |input|
          app.call(
            'HTTP_VERSION'   => 'HTTP/1.1',
            'REQUEST_METHOD' => method, 'PATH_INFO'  => pinfo,
            'QUERY_STRING'   => query , 'SCRIPT_NAME'=> ''   ,
            'rack.input'     => input ,
            'rack.hijack'    => lambda{
              sock = StringIO.new
              # or TypeError: no implicit conversion of StringIO into IO
              mock(IO).select([sock]){ [[sock], [], []] }
              sock
            })
        end

        if hijack = headers.delete('rack.hijack')
          sock = StringIO.new
          hijack.call(sock)
          body = sock.string.each_line("\n\n")
        end

        body.extend(Enumerable)
        [status, headers, body.to_a].should.eq eval(expect, binding, __FILE__)
      end
    end
  end
end
