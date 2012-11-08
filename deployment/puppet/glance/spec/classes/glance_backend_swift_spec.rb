require 'spec_helper'

describe 'glance::backend::swift' do
  let :facts do
    {
      :concat_basedir => '/var/lib/puppet/concat',
      :osfamily => 'Debian'
    }
  end
  let :params do
    {
      'swift_store_user' => 'glance',
      'swift_store_key'  => 'glance_key'
    }
  end
  it 'should set the default store to file' do
    verify_contents(
      subject,
      '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/04_glance-api-backend',
      ['default_store = swift']
    )
  end
  it 'should configure swift settings with defaults' do
    verify_contents(
      subject,
      '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/05_glance-api-swift',
      [
        'swift_store_auth_address = 127.0.0.1:8080/v1.0/',
        'swift_store_user = glance',
        'swift_store_key = glance_key',
        'swift_store_container = glance',
        'swift_store_create_container_on_put = False'
      ]
    )
  end
  describe 'when datadir is overridden' do
    let :params do
      {
      'swift_store_user'                    => 'glance',
      'swift_store_key'                     => 'glance_key',
      'swift_store_container'               => 'glance2',
      'swift_store_auth_address'            => '127.0.0.1:8080/v2.0/',
      'swift_store_create_container_on_put' => 'True'
      }
    end

    it 'should configure file backend settings with specified parameter' do
      verify_contents(
        subject,
        '/var/lib/puppet/concat/_etc_glance_glance-api.conf/fragments/05_glance-api-swift',
        [
          'swift_store_auth_address = 127.0.0.1:8080/v2.0/',
          'swift_store_user = glance',
          'swift_store_key = glance_key',
          'swift_store_container = glance2',
          'swift_store_create_container_on_put = True'
        ]
      )
    end
  end
end
