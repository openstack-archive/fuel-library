require 'spec_helper'

describe 'keystone' do

  let :facts do
    {:osfamily => 'Debian'}
  end

  let :default_params do
    {
      'package_ensure'   => 'present',
      'bind_host'        => '0.0.0.0',
      'public_port'      => '5000',
      'admin_port'       => '35357',
      'admin_token'      => 'service_token',
      'compute_port'     => '8774',
      'verbose'          => false,
      'debug'            => false,
      'catalog_type'     => 'sql',
      'token_provider'   => 'keystone.token.providers.pki.Provider',
      'token_driver'     => 'keystone.token.backends.sql.Token',
      'cache_dir'        => '/var/cache/keystone',
      'enable_ssl'       => false,
      'ssl_certfile'     => '/etc/keystone/ssl/certs/keystone.pem',
      'ssl_keyfile'      => '/etc/keystone/ssl/private/keystonekey.pem',
      'ssl_ca_certs'     => '/etc/keystone/ssl/certs/ca.pem',
      'ssl_ca_key'       => '/etc/keystone/ssl/private/cakey.pem',
      'ssl_cert_subject' => '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
      'enabled'          => true,
      'sql_connection'   => 'sqlite:////var/lib/keystone/keystone.db',
      'idle_timeout'     => '200'
    }
  end

  [{'admin_token'     => 'service_token'},
   {
      'package_ensure'   => 'latest',
      'bind_host'        => '127.0.0.1',
      'public_port'      => '5001',
      'admin_port'       => '35358',
      'admin_token'      => 'service_token_override',
      'compute_port'     => '8778',
      'verbose'          => true,
      'debug'            => true,
      'catalog_type'     => 'template',
      'token_provider'   => 'keystone.token.providers.uuid.Provider',
      'token_driver'     => 'keystone.token.backends.kvs.Token',
      'public_endpoint'  => 'https://localhost:5000/v2.0/',
      'admin_endpoint'   => 'https://localhost:35357/v2.0/',
      'enable_ssl'       => true,
      'ssl_certfile'     => '/etc/keystone/ssl/certs/keystone.pem',
      'ssl_keyfile'      => '/etc/keystone/ssl/private/keystonekey.pem',
      'ssl_ca_certs'     => '/etc/keystone/ssl/certs/ca.pem',
      'ssl_ca_key'       => '/etc/keystone/ssl/private/cakey.pem',
      'ssl_cert_subject' => '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
      'enabled'          => false,
      'sql_connection'   => 'mysql://a:b@c/d',
      'idle_timeout'     => '300'
    }
  ].each do |param_set|

    describe "when #{param_set == {} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      it { should contain_class('keystone::params') }

      it { should contain_package('keystone').with(
        'ensure' => param_hash['package_ensure']
      ) }

      it { should contain_group('keystone').with(
          'ensure' => 'present',
          'system' => true
      ) }
      it { should contain_user('keystone').with(
        'ensure' => 'present',
        'gid'    => 'keystone',
        'system' => true
      ) }

      it 'should contain the expected directories' do
        ['/etc/keystone', '/var/log/keystone', '/var/lib/keystone'].each do |d|
          should contain_file(d).with(
            'ensure'     => 'directory',
            'owner'      => 'keystone',
            'group'      => 'keystone',
            'mode'       => '0750',
            'require'    => 'Package[keystone]'
          )
        end
      end

      it { should contain_service('keystone').with(
        'ensure'     => param_hash['enabled'] ? 'running' : 'stopped',
        'enable'     => param_hash['enabled'],
        'hasstatus'  => true,
        'hasrestart' => true
      ) }

      it 'should only migrate the db if $enabled is true' do
        if param_hash['enabled']
          should contain_exec('keystone-manage db_sync').with(
            :user        => 'keystone',
            :refreshonly => true,
            :subscribe   => ['Package[keystone]', 'Keystone_config[sql/connection]'],
            :require     => 'User[keystone]'
          )
        end
      end

      it 'should contain correct config' do
        [
          'admin_token',
          'bind_host',
          'public_port',
          'admin_port',
          'compute_port',
          'verbose',
          'debug'
        ].each do |config|
          should contain_keystone_config("DEFAULT/#{config}").with_value(param_hash[config])
        end
      end

      it 'should contain correct mysql config' do
        should contain_keystone_config('sql/idle_timeout').with_value(param_hash['idle_timeout'])
        should contain_keystone_config('sql/connection').with_value(param_hash['sql_connection'])
      end

      it { should contain_keystone_config('token/provider').with_value(
        param_hash['token_provider']
      ) }

      it 'should contain correct token driver' do
        should contain_keystone_config('token/driver').with_value(param_hash['token_driver'])
      end

      it 'should ensure proper setting of admin_endpoint and public_endpoint' do
        if param_hash['admin_endpoint']
          should contain_keystone_config('DEFAULT/admin_endpoint').with_value(param_hash['admin_endpoint'])
        else
          should contain_keystone_config('DEFAULT/admin_endpoint').with_ensure('absent')
        end
        if param_hash['public_endpoint']
          should contain_keystone_config('DEFAULT/public_endpoint').with_value(param_hash['public_endpoint'])
        else
          should contain_keystone_config('DEFAULT/public_endpoint').with_ensure('absent')
        end
      end
    end
  end

  describe 'when configuring signing token provider' do

    describe 'when configuring as UUID' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_provider' => 'keystone.token.providers.uuid.Provider'
        }
      end
      it { should_not contain_exec('keystone-manage pki_setup') }
    end

    describe 'when configuring as PKI' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_provider' => 'keystone.token.providers.pki.Provider'
        }
      end
      it { should contain_exec('keystone-manage pki_setup').with(
        :creates => '/etc/keystone/ssl/private/signing_key.pem'
      ) }
      it { should contain_file('/var/cache/keystone').with_ensure('directory') }

      describe 'when overriding the cache dir' do
        before do
          params.merge!(:cache_dir => '/var/lib/cache/keystone')
        end
        it { should contain_file('/var/lib/cache/keystone') }
      end

      describe 'when disable pki_setup' do
        before do
          params.merge!(:enable_pki_setup => false)
        end
        it { should_not contain_exec('keystone-manage pki_setup') }
      end
    end

    describe 'when configuring deprecated token_format as UUID' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_format'   => 'UUID'
        }
      end
      it { should_not contain_exec('keystone-manage pki_setup') }
    end

    describe 'when configuring deprecated token_format as PKI' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_format'   => 'PKI'
        }
      end
      it { should contain_exec('keystone-manage pki_setup').with(
        :creates => '/etc/keystone/ssl/private/signing_key.pem'
      ) }
      it { should contain_file('/var/cache/keystone').with_ensure('directory') }
      describe 'when overriding the cache dir' do
        let :params do
          {
            'admin_token'    => 'service_token',
            'token_provider' => 'keystone.token.providers.pki.Provider',
            'cache_dir'      => '/var/lib/cache/keystone'
          }
        end
        it { should contain_file('/var/lib/cache/keystone') }
      end
    end

  end

  describe 'when configuring token expiration' do
    let :params do
      {
        'admin_token'      => 'service_token',
        'token_expiration' => '42',
      }
    end

    it { should contain_keystone_config("token/expiration").with_value('42') }
  end

  describe 'when not configuring token expiration' do
    let :params do
      {
        'admin_token' => 'service_token',
      }
    end

    it { should contain_keystone_config("token/expiration").with_value('86400') }
  end

  describe 'configure memcache servers if set' do
    let :params do
      {
        'admin_token'      => 'service_token',
        'memcache_servers' => [ 'SERVER1:11211', 'SERVER2:11211' ],
        'token_driver'     => 'keystone.token.backends.memcache.Token'
      }
    end

    it { should contain_keystone_config("memcache/servers").with_value('SERVER1:11211,SERVER2:11211') }
  end

  describe 'do not configure memcache servers when not set' do
    let :params do
      default_params
    end

    it { should contain_keystone_config("memcache/servers").with_ensure('absent') }
  end

  describe 'raise error if memcache_servers is not an array' do
    let :params do
      {
        'admin_token'      => 'service_token',
        'memcache_servers' => 'ANY_SERVER:11211'
      }
    end

    it { expect { should contain_class('keystone::params') }.to \
      raise_error(Puppet::Error, /is not an Array/) }
  end

  describe 'with syslog disabled by default' do
    let :params do
      default_params
    end

    it { should contain_keystone_config('DEFAULT/use_syslog').with_value(false) }
    it { should_not contain_keystone_config('DEFAULT/syslog_log_facility') }
  end

  describe 'with syslog enabled' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { should contain_keystone_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_keystone_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
  end

  describe 'with syslog enabled and custom settings' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
        :log_facility => 'LOG_LOCAL0'
     })
    end

    it { should contain_keystone_config('DEFAULT/use_syslog').with_value(true) }
    it { should contain_keystone_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
  end

  describe 'with log_dir disabled' do
    let(:params) { default_params.merge({:log_dir => false}) }
    it { should contain_keystone_config('DEFAULT/log_dir').with_ensure('absent') }
  end

  describe 'when configuring as SSL' do
    let :params do
      {
        'admin_token' => 'service_token',
        'enable_ssl'  => true
      }
    end
    it { should contain_exec('keystone-manage pki_setup').with(
      :creates => '/etc/keystone/ssl/private/signing_key.pem'
    ) }
    it { should contain_file('/var/cache/keystone').with_ensure('directory') }
    describe 'when overriding the cache dir' do
      let :params do
        {
          'admin_token' => 'service_token',
          'enable_ssl'  => true,
          'cache_dir'   => '/var/lib/cache/keystone'
        }
      end
      it { should contain_file('/var/lib/cache/keystone') }
    end
  end
  describe 'when enabling SSL' do
    let :params do
      {
        'admin_token' => 'service_token',
        'enable_ssl'  => true,
        'public_endpoint'  => 'https://localhost:5000/v2.0/',
        'admin_endpoint'   => 'https://localhost:35357/v2.0/',
      }
    end
    it {should contain_keystone_config('ssl/enable').with_value(true)}
    it {should contain_keystone_config('ssl/certfile').with_value('/etc/keystone/ssl/certs/keystone.pem')}
    it {should contain_keystone_config('ssl/keyfile').with_value('/etc/keystone/ssl/private/keystonekey.pem')}
    it {should contain_keystone_config('ssl/ca_certs').with_value('/etc/keystone/ssl/certs/ca.pem')}
    it {should contain_keystone_config('ssl/ca_key').with_value('/etc/keystone/ssl/private/cakey.pem')}
    it {should contain_keystone_config('ssl/cert_subject').with_value('/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost')}
    it {should contain_keystone_config('DEFAULT/public_endpoint').with_value('https://localhost:5000/v2.0/')}
    it {should contain_keystone_config('DEFAULT/admin_endpoint').with_value('https://localhost:35357/v2.0/')}
  end
  describe 'when disabling SSL' do
    let :params do
      {
        'admin_token' => 'service_token',
        'enable_ssl'  => false,
      }
    end
    it {should contain_keystone_config('ssl/enable').with_value(false)}
    it {should contain_keystone_config('DEFAULT/public_endpoint').with_ensure('absent')}
    it {should contain_keystone_config('DEFAULT/admin_endpoint').with_ensure('absent')}
  end
end
