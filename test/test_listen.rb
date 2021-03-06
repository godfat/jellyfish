
require 'jellyfish/test'
require 'jellyfish/urlmap'

describe Jellyfish::URLMap do
  paste :jellyfish

  lam = lambda{ |env| [200, {}, ["lam #{env['HTTP_HOST']}"]] }
  ram = lambda{ |env| [200, {}, ["ram #{env['HTTP_HOST']}"]] }

  def call app, host, path: '/', scheme: 'http'
    get('/', app,
      'HTTP_HOST' => host,
      'PATH_INFO' => path,
      'rack.url_scheme' => scheme).dig(-1, 0)
  end

  would 'map host' do
    app = Jellyfish::Builder.app do
      map '/', host: 'host' do
        run lam
      end

      run ram
    end

    expect(call(app, 'host')).eq 'lam host'
    expect(call(app, 'lust')).eq 'ram lust'
  end

  would 'map host with path' do
    app = Jellyfish::Builder.app do
      map '/path', host: 'host' do
        run lam
      end

      map '/path' do
        run ram
      end
    end

    expect(call(app, 'host', path: '/path')).eq 'lam host'
    expect(call(app, 'lust', path: '/path')).eq 'ram lust'
  end

  would 'map longest path first' do
    app = Jellyfish::Builder.app do
      map '/long/path' do
        run lam
      end

      map '/', host: 'super-long-host' do
        run ram
      end
    end

    expect(call(app, 'super-long-host', path: '/long/path')).
      eq 'lam super-long-host'
  end

  would 'map host with http or https' do
    app = Jellyfish::Builder.app do
      map '/', host: 'host' do
        run lam
      end
    end

    expect(call(app, 'host')).eq 'lam host'
    expect(call(app, 'host', scheme: 'https')).eq 'lam host'
  end

  would 'map http with http or https' do
    app = Jellyfish::Builder.app do
      map 'http://host/' do
        run lam
      end
    end

    expect(call(app, 'host')).eq 'lam host'
    expect(call(app, 'host', scheme: 'https')).eq 'lam host'
  end

  would 'listen' do
    app = Jellyfish::Builder.app do
      listen 'host' do
        run lam
      end

      listen 'lust' do
        run ram
      end
    end

    expect(call(app, 'host')).eq 'lam host'
    expect(call(app, 'lust')).eq 'ram lust'
    expect(call(app, 'boom')).eq nil
  end

  would 'nest' do
    app = Jellyfish::Builder.app do
      listen 'host' do
        map '/host' do
          run lam
        end
      end

      listen 'lust' do
        map '/lust' do
          run ram
        end
      end
    end

    expect(call(app, 'host', path: '/host')).eq 'lam host'
    expect(call(app, 'lust', path: '/lust')).eq 'ram lust'
    expect(call(app, 'boom', path: '/host')).eq nil
    expect(call(app, 'boom', path: '/lust')).eq nil
  end
end
