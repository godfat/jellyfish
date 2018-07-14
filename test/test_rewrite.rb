
require 'jellyfish/test'
require 'jellyfish/urlmap'

describe Jellyfish::Rewrite do
  paste :jellyfish

  lam = lambda{ |env| [200, {}, [env['PATH_INFO']]] }

  def call app, path
    get(path, app).dig(-1, 0)
  end

  would 'map to' do
    app = Jellyfish::Builder.app do
      map '/from', to: '/to' do
        run lam
      end
    end

    expect(call(app, '/from')).eq '/to'
  end

  would 'rewrite and fallback' do
    app = Jellyfish::Builder.app do
      rewrite '/from/inner' => '/to/inner',
              '/from/outer' => '/to/outer' do
        run lam
      end

      map '/from' do
        run lam
      end
    end

    expect(call(app, '/from'      )).eq ''
    expect(call(app, '/from/inner')).eq '/to/inner'
    expect(call(app, '/from/outer')).eq '/to/outer'
  end
end
