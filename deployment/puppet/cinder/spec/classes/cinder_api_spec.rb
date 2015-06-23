require 'spec_helper'

describe 'cinder::api' do

  let :req_params do
    {:keystone_password => 'foo'}
  end
  let :facts do
    {:osfamily       => 'Debian',
     :processorcount => 8 }
  end

  describe 'with only required params' do
    let :params do
      req_params
    end

    it { is_expected.to contain_service('cinder-api').with(
      'hasstatus' => true,
      'ensure' => 'running'
    )}

    it 'should configure cinder api correctly' do
      is_expected.to contain_cinder_config('DEFAULT/auth_strategy').with(
       :value => 'keystone'
      )
      is_expected.to contain_cinder_config('DEFAULT/osapi_volume_listen').with(
       :value => '0.0.0.0'
      )
      is_expected.to contain_cinder_config('DEFAULT/osapi_volume_workers').with(
       :value => '8'
      )
      is_expected.to contain_cinder_config('DEFAULT/default_volume_type').with(
       :ensure => 'absent'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_protocol').with(
        :value => 'http'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_host').with(
        :value => 'localhost'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_port').with(
        :value => '5000'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_protocol').with(
        :value => 'http'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_host').with(
        :value => 'localhost'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_port').with(
        :value => '35357'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix').with(
        :ensure => 'absent'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/admin_tenant_name').with(
        :value => 'services'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/admin_user').with(
        :value => 'cinder'
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/admin_password').with(
        :value  => 'foo',
        :secret => true
      )
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_uri').with(
        :value => 'http://localhost:5000/'
      )

      is_expected.to_not contain_cinder_config('DEFAULT/os_region_name')

    end
  end

  describe 'with a custom region for nova' do
    let :params do
      req_params.merge({'os_region_name' => 'MyRegion'})
    end
    it 'should configure the region for nova' do
      is_expected.to contain_cinder_config('DEFAULT/os_region_name').with(
        :value => 'MyRegion'
      )
    end
  end

  describe 'with a default volume type' do
    let :params do
      req_params.merge({'default_volume_type' => 'foo'})
    end
    it 'should configure the default volume type for cinder' do
      is_expected.to contain_cinder_config('DEFAULT/default_volume_type').with(
        :value => 'foo'
      )
    end
  end

  describe 'with custom auth_uri' do
    let :params do
      req_params.merge({'keystone_auth_uri' => 'http://localhost:8080/v2.0/'})
    end
    it 'should configure cinder auth_uri correctly' do
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_uri').with(
        :value => 'http://localhost:8080/v2.0/'
      )
    end
  end

  describe 'with only required params' do
    let :params do
      req_params.merge({'bind_host' => '192.168.1.3'})
    end
    it 'should configure cinder api correctly' do
      is_expected.to contain_cinder_config('DEFAULT/osapi_volume_listen').with(
       :value => '192.168.1.3'
      )
    end
  end

  describe 'with sync_db set to false' do
    let :params do
      {
        :keystone_password => 'dummy',
        :enabled           => 'true',
        :sync_db           => false,
      }
    end
    it { is_expected.not_to contain_exec('cinder-manage db_sync') }
  end

  [ '/keystone', '/keystone/admin' ].each do |keystone_auth_admin_prefix|
    describe "with keystone_auth_admin_prefix containing correct value #{keystone_auth_admin_prefix}" do
      let :params do
        {
          :keystone_auth_admin_prefix => keystone_auth_admin_prefix,
          :keystone_password    => 'dummy'
        }
      end

      it { is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix').with(
        :value => "#{keystone_auth_admin_prefix}"
      )}
    end
  end

  describe "with keystone_auth_admin_prefix containing correct value ''" do
    let :params do
      {
        :keystone_auth_admin_prefix => '',
        :keystone_password          => 'dummy'
      }
    end

    it { is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix')}
  end

  [
    '/keystone/',
    'keystone/',
    'keystone',
    '/keystone/admin/',
    'keystone/admin/',
    'keystone/admin'
  ].each do |keystone_auth_admin_prefix|
    describe "with keystone_auth_admin_prefix containing incorrect value #{keystone_auth_admin_prefix}" do
      let :params do
        {
          :keystone_auth_admin_prefix => keystone_auth_admin_prefix,
          :keystone_password    => 'dummy'
        }
      end

      it { expect { is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix') }.to \
        raise_error(Puppet::Error, /validate_re\(\): "#{keystone_auth_admin_prefix}" does not match/) }
    end
  end

  describe 'with enabled false' do
    let :params do
      req_params.merge({'enabled' => false})
    end
    it 'should stop the service' do
      is_expected.to contain_service('cinder-api').with_ensure('stopped')
    end
    it 'should contain db_sync exec' do
      is_expected.to contain_exec('cinder-manage db_sync')
    end
  end

  describe 'with manage_service false' do
    let :params do
      req_params.merge({'manage_service' => false})
    end
    it 'should not change the state of the service' do
      is_expected.to contain_service('cinder-api').without_ensure
    end
    it 'should contain db_sync exec' do
      is_expected.to contain_exec('cinder-manage db_sync')
    end
  end

  describe 'with ratelimits' do
    let :params do
      req_params.merge({ :ratelimits => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)' })
    end

    it { is_expected.to contain_cinder_api_paste_ini('filter:ratelimit/limits').with(
      :value => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)'
    )}
  end

  describe 'while validating the service with default command' do
    let :params do
      req_params.merge({
        :validate => true,
      })
    end
    it { is_expected.to contain_exec('execute cinder-api validation').with(
      :path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      :provider    => 'shell',
      :tries       => '10',
      :try_sleep   => '2',
      :command     => 'cinder --os-auth-url http://localhost:5000/ --os-tenant-name services --os-username cinder --os-password foo list',
    )}

    it { is_expected.to contain_anchor('create cinder-api anchor').with(
      :require => 'Exec[execute cinder-api validation]',
    )}
  end

  describe 'while validating the service with custom command' do
    let :params do
      req_params.merge({
        :validate            => true,
        :validation_options  => { 'cinder-api' => { 'command' => 'my-script' } }
      })
    end
    it { is_expected.to contain_exec('execute cinder-api validation').with(
      :path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      :provider    => 'shell',
      :tries       => '10',
      :try_sleep   => '2',
      :command     => 'my-script',
    )}

    it { is_expected.to contain_anchor('create cinder-api anchor').with(
      :require => 'Exec[execute cinder-api validation]',
    )}
  end

  describe "with custom keystone identity_uri and auth_uri" do
    let :params do
      req_params.merge({
        :identity_uri         => 'https://localhost:35357/',
        :auth_uri             => 'https://localhost:5000/v2.0/',
      })
    end
    it 'configures identity_uri and auth_uri but deprecates old auth settings' do
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/identity_uri').with_value("https://localhost:35357/");
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_uri').with_value("https://localhost:5000/v2.0/");
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_admin_prefix').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_port').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_port').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_protocol').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_protocol').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/auth_host').with(:ensure => 'absent')
      is_expected.to contain_cinder_api_paste_ini('filter:authtoken/service_host').with(:ensure => 'absent')
    end
  end

  describe 'when someone sets keystone_auth_uri and auth_uri' do
    let :params do
      req_params.merge({
          :keystone_auth_uri    => 'http://thisis',
          :auth_uri             => 'http://broken',
        })
    end

    it_raises 'a Puppet::Error', /both keystone_auth_uri and auth_uri are set and they have the same meaning/
  end
end
