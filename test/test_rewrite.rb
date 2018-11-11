
require 'jellyfish/test'
require 'jellyfish/urlmap'

describe Jellyfish::Rewrite do
  paste :jellyfish

  lam = lambda do |env|
    [200, {}, ["#{env['SCRIPT_NAME']}!#{env['PATH_INFO']}"]]
  end

  def call app, path
    get(path, app).dig(-1, 0)
  end

  would 'map to' do
    app = Jellyfish::Builder.app do
      map '/from', to: '/to' do
        run lam
      end
    end

    expect(call(app, '/from/here')).eq '!/to/here'
  end

  would 'rewrite and fallback' do
    app = Jellyfish::Builder.app do
      map '/top' do
        rewrite '/from/inner' => '/to/inner',
                '/from/outer' => '/to/outer' do
          run lam
        end

        map '/from' do
          run lam
        end
      end
    end

    expect(call(app, '/top/from/other')).eq '/top/from!/other'
    expect(call(app, '/top/from/inner')).eq '/top!/to/inner'
    expect(call(app, '/top/from/outer')).eq '/top!/to/outer'
  end

  would 'map to with host and handle SCRIPT_NAME properly' do
    app = Jellyfish::Builder.app do
      map '/path', to: '/path', host: 'host' do
        run lambda{ |env|
          [200, {},
            ["#{env['HTTP_HOST']} #{env['SCRIPT_NAME']} #{env['PATH_INFO']}"]]
        }
      end
    end

    expect(get('/path', app, 'HTTP_HOST' => 'host').dig(-1, -1)).
      eq 'host  /path'
  end
end
