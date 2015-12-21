
require 'jellyfish/test'
require 'jellyfish/urlmap'

describe Jellyfish::Rewrite do
  lam = lambda{ |env| [200, {}, [env['PATH_INFO']]] }

  def call app, env={}
    app.call({'SCRIPT_NAME' => ''}.merge(env)).last.first
  end

  would 'map to' do
    app = Jellyfish::Builder.app do
      map '/from', to: '/to' do
        run lam
      end
    end

    expect(call(app, 'PATH_INFO' => '/from')).eq '/to'
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

    expect(call(app, 'PATH_INFO' => '/from'      )).eq ''
    expect(call(app, 'PATH_INFO' => '/from/inner')).eq '/to/inner'
    expect(call(app, 'PATH_INFO' => '/from/outer')).eq '/to/outer'
  end
end
