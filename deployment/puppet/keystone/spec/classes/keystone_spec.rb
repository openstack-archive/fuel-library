require 'spec_helper'

describe 'keystone' do

  let :global_facts do
    {
      :processorcount => 42,
      :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  let :facts do
    global_facts.merge({
      :osfamily               => 'Debian',
      :operatingsystem        => 'Debian',
      :operatingsystemrelease => '7.0',
      :processorcount         => '1'
    })
  end

  default_params = {
      'admin_token'           => 'service_token',
      'package_ensure'        => 'present',
      'client_package_ensure' => 'present',
      'public_bind_host'      => '0.0.0.0',
      'admin_bind_host'       => '0.0.0.0',
      'public_port'           => '5000',
      'admin_port'            => '35357',
      'admin_token'           => 'service_token',
      'verbose'               => false,
      'debug'                 => false,
      'catalog_type'          => 'sql',
      'catalog_driver'        => false,
      'token_provider'        => 'keystone.token.providers.uuid.Provider',
      'token_driver'          => 'keystone.token.persistence.backends.sql.Token',
      'revoke_driver'         => 'keystone.contrib.revoke.backends.sql.Revoke',
      'cache_dir'             => '/var/cache/keystone',
      'enable_ssl'            => false,
      'ssl_certfile'          => '/etc/keystone/ssl/certs/keystone.pem',
      'ssl_keyfile'           => '/etc/keystone/ssl/private/keystonekey.pem',
      'ssl_ca_certs'          => '/etc/keystone/ssl/certs/ca.pem',
      'ssl_ca_key'            => '/etc/keystone/ssl/private/cakey.pem',
      'ssl_cert_subject'      => '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
      'enabled'               => true,
      'manage_service'        => true,
      'database_connection'   => 'sqlite:////var/lib/keystone/keystone.db',
      'database_idle_timeout' => '200',
      'enable_pki_setup'      => true,
      'signing_certfile'      => '/etc/keystone/ssl/certs/signing_cert.pem',
      'signing_keyfile'       => '/etc/keystone/ssl/private/signing_key.pem',
      'signing_ca_certs'      => '/etc/keystone/ssl/certs/ca.pem',
      'signing_ca_key'        => '/etc/keystone/ssl/private/cakey.pem',
      'rabbit_host'           => 'localhost',
      'rabbit_password'       => 'guest',
      'rabbit_userid'         => 'guest',
      'admin_workers'         => 20,
      'public_workers'        => 20,
      'sync_db'               => true,
    }

  override_params = {
      'package_ensure'        => 'latest',
      'client_package_ensure' => 'latest',
      'public_bind_host'      => '0.0.0.0',
      'admin_bind_host'       => '0.0.0.0',
      'public_port'           => '5001',
      'admin_port'            => '35358',
      'admin_token'           => 'service_token_override',
      'verbose'               => true,
      'debug'                 => true,
      'catalog_type'          => 'template',
      'token_provider'        => 'keystone.token.providers.uuid.Provider',
      'token_driver'          => 'keystone.token.backends.kvs.Token',
      'revoke_driver'         => 'keystone.contrib.revoke.backends.kvs.Revoke',
      'public_endpoint'       => 'https://localhost:5000/v2.0/',
      'admin_endpoint'        => 'https://localhost:35357/v2.0/',
      'enable_ssl'            => true,
      'ssl_certfile'          => '/etc/keystone/ssl/certs/keystone.pem',
      'ssl_keyfile'           => '/etc/keystone/ssl/private/keystonekey.pem',
      'ssl_ca_certs'          => '/etc/keystone/ssl/certs/ca.pem',
      'ssl_ca_key'            => '/etc/keystone/ssl/private/cakey.pem',
      'ssl_cert_subject'      => '/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost',
      'enabled'               => false,
      'manage_service'        => true,
      'database_connection'   => 'mysql://a:b@c/d',
      'database_idle_timeout' => '300',
      'enable_pki_setup'      => true,
      'signing_certfile'      => '/etc/keystone/ssl/certs/signing_cert.pem',
      'signing_keyfile'       => '/etc/keystone/ssl/private/signing_key.pem',
      'signing_ca_certs'      => '/etc/keystone/ssl/certs/ca.pem',
      'signing_ca_key'        => '/etc/keystone/ssl/private/cakey.pem',
      'rabbit_host'           => '127.0.0.1',
      'rabbit_password'       => 'openstack',
      'rabbit_userid'         => 'admin',
    }

  httpd_params = {'service_name' => 'httpd'}.merge(default_params)

  shared_examples_for 'core keystone examples' do |param_hash|
    it { is_expected.to contain_class('keystone::params') }

    it { is_expected.to contain_package('keystone').with(
      'ensure' => param_hash['package_ensure'],
      'tag'    => 'openstack'
    ) }

    it { is_expected.to contain_package('python-openstackclient').with(
      'ensure' => param_hash['client_package_ensure'],
      'tag'    => 'openstack'
    ) }

    it { is_expected.to contain_group('keystone').with(
      'ensure' => 'present',
      'system' => true
    ) }

    it { is_expected.to contain_user('keystone').with(
      'ensure' => 'present',
      'gid'    => 'keystone',
      'system' => true
    ) }

    it 'should contain the expected directories' do
      ['/etc/keystone', '/var/log/keystone', '/var/lib/keystone'].each do |d|
        is_expected.to contain_file(d).with(
          'ensure'     => 'directory',
          'owner'      => 'keystone',
          'group'      => 'keystone',
          'mode'       => '0750',
          'require'    => 'Package[keystone]'
        )
      end
    end

    it 'should synchronize the db if $sync_db is true' do
      if param_hash['sync_db']
        is_expected.to contain_exec('keystone-manage db_sync').with(
          :user        => 'keystone',
          :refreshonly => true,
          :subscribe   => ['Package[keystone]', 'Keystone_config[database/connection]'],
          :require     => 'User[keystone]'
        )
      end
    end

    it 'should contain correct config' do
      [
       'public_bind_host',
       'admin_bind_host',
       'public_port',
       'admin_port',
       'verbose',
       'debug'
      ].each do |config|
        is_expected.to contain_keystone_config("DEFAULT/#{config}").with_value(param_hash[config])
      end
    end

    it 'should contain correct admin_token config' do
      is_expected.to contain_keystone_config('DEFAULT/admin_token').with_value(param_hash['admin_token']).with_secret(true)
    end

    it 'should contain correct mysql config' do
      is_expected.to contain_keystone_config('database/idle_timeout').with_value(param_hash['database_idle_timeout'])
      is_expected.to contain_keystone_config('database/connection').with_value(param_hash['database_connection']).with_secret(true)
    end

    it { is_expected.to contain_keystone_config('token/provider').with_value(
      param_hash['token_provider']
    ) }

    it 'should contain correct token driver' do
      is_expected.to contain_keystone_config('token/driver').with_value(param_hash['token_driver'])
    end

    it 'should contain correct revoke driver' do
      should contain_keystone_config('revoke/driver').with_value(param_hash['revoke_driver'])
    end

    it 'should ensure proper setting of admin_endpoint and public_endpoint' do
      if param_hash['admin_endpoint']
        is_expected.to contain_keystone_config('DEFAULT/admin_endpoint').with_value(param_hash['admin_endpoint'])
      else
        is_expected.to contain_keystone_config('DEFAULT/admin_endpoint').with_ensure('absent')
      end
      if param_hash['public_endpoint']
        is_expected.to contain_keystone_config('DEFAULT/public_endpoint').with_value(param_hash['public_endpoint'])
      else
        is_expected.to contain_keystone_config('DEFAULT/public_endpoint').with_ensure('absent')
      end
    end

    it 'should contain correct rabbit_password' do
      is_expected.to contain_keystone_config('DEFAULT/rabbit_password').with_value(param_hash['rabbit_password']).with_secret(true)
    end

    it 'should remove max_token_size param by default' do
      is_expected.to contain_keystone_config('DEFAULT/max_token_size').with_ensure('absent')
    end

    it 'should ensure proper setting of admin_workers and public_workers' do
      if param_hash['admin_workers']
        is_expected.to contain_keystone_config('DEFAULT/admin_workers').with_value(param_hash['admin_workers'])
      else
        is_expected.to contain_keystone_config('DEFAULT/admin_workers').with_value('2')
      end
      if param_hash['public_workers']
        is_expected.to contain_keystone_config('DEFAULT/public_workers').with_value(param_hash['public_workers'])
      else
        is_expected.to contain_keystone_config('DEFAULT/public_workers').with_value('2')
      end
    end
  end

  [default_params, override_params].each do |param_hash|
    describe "when #{param_hash == default_params ? "using default" : "specifying"} class parameters for service" do

      let :params do
        param_hash
      end

      it_configures 'core keystone examples', param_hash

      it { is_expected.to contain_service('keystone').with(
        'ensure'     => (param_hash['manage_service'] && param_hash['enabled']) ? 'running' : 'stopped',
        'enable'     => param_hash['enabled'],
        'hasstatus'  => true,
        'hasrestart' => true
      ) }

    end
  end

  shared_examples_for "when using default class parameters for httpd" do
    let :params do
      httpd_params
    end

    let :pre_condition do
      'include ::apache'
    end

    it_configures 'core keystone examples', httpd_params

    it do
      expect {
        should contain_service(platform_parameters[:service_name]).with('ensure' => 'running')
      }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /expected that the catalogue would contain Service\[#{platform_parameters[:service_name]}\]/)
    end

    it { should contain_class('keystone::service').with(
      'ensure'          => 'stopped',
      'service_name'    => platform_parameters[:service_name],
      'enable'          => false,
      'validate'        => false
    )}
  end

  describe 'when using invalid service name for keystone' do
    let (:params) { {'service_name' => 'foo'}.merge(default_params) }

    it_raises 'a Puppet::Error', /Invalid service_name/
  end

  describe 'with disabled service managing' do
    let :params do
      { :admin_token    => 'service_token',
        :manage_service => false,
        :enabled        => false }
    end

    it { is_expected.to contain_service('keystone').with(
      'ensure'     => nil,
      'enable'     => false,
      'hasstatus'  => true,
      'hasrestart' => true
    ) }
  end

  describe 'when configuring signing token provider' do

    describe 'when configuring as UUID' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_provider' => 'keystone.token.providers.uuid.Provider'
        }
      end
      it { is_expected.to contain_exec('keystone-manage pki_setup').with(
        :creates => '/etc/keystone/ssl/private/signing_key.pem'
      ) }
      it { is_expected.to contain_file('/var/cache/keystone').with_ensure('directory') }

      describe 'when overriding the cache dir' do
        before do
          params.merge!(:cache_dir => '/var/lib/cache/keystone')
        end
        it { is_expected.to contain_file('/var/lib/cache/keystone') }
      end

      describe 'when disable pki_setup' do
        before do
          params.merge!(:enable_pki_setup => false)
        end
        it { is_expected.to_not contain_exec('keystone-manage pki_setup') }
      end
    end

    describe 'when configuring as PKI' do
      let :params do
        {
          'admin_token'    => 'service_token',
          'token_provider' => 'keystone.token.providers.pki.Provider'
        }
      end
      it { is_expected.to contain_exec('keystone-manage pki_setup').with(
        :creates => '/etc/keystone/ssl/private/signing_key.pem'
      ) }
      it { is_expected.to contain_file('/var/cache/keystone').with_ensure('directory') }

      describe 'when overriding the cache dir' do
        before do
          params.merge!(:cache_dir => '/var/lib/cache/keystone')
        end
        it { is_expected.to contain_file('/var/lib/cache/keystone') }
      end

      describe 'when disable pki_setup' do
        before do
          params.merge!(:enable_pki_setup => false)
        end
        it { is_expected.to_not contain_exec('keystone-manage pki_setup') }
      end
    end

    describe 'when configuring PKI signing cert paths with UUID and with pki_setup disabled' do
      let :params do
        {
          'admin_token'          => 'service_token',
          'token_provider'       => 'keystone.token.providers.uuid.Provider',
          'enable_pki_setup'     => false,
          'signing_certfile'     => 'signing_certfile',
          'signing_keyfile'      => 'signing_keyfile',
          'signing_ca_certs'     => 'signing_ca_certs',
          'signing_ca_key'       => 'signing_ca_key',
          'signing_cert_subject' => 'signing_cert_subject',
          'signing_key_size'     => 2048
        }
      end

      it { is_expected.to_not contain_exec('keystone-manage pki_setup') }

      it 'should contain correct PKI certfile config' do
        is_expected.to contain_keystone_config('signing/certfile').with_value('signing_certfile')
      end

      it 'should contain correct PKI keyfile config' do
        is_expected.to contain_keystone_config('signing/keyfile').with_value('signing_keyfile')
      end

      it 'should contain correct PKI ca_certs config' do
        is_expected.to contain_keystone_config('signing/ca_certs').with_value('signing_ca_certs')
      end

      it 'should contain correct PKI ca_key config' do
        is_expected.to contain_keystone_config('signing/ca_key').with_value('signing_ca_key')
      end

      it 'should contain correct PKI cert_subject config' do
        is_expected.to contain_keystone_config('signing/cert_subject').with_value('signing_cert_subject')
      end

      it 'should contain correct PKI key_size config' do
        is_expected.to contain_keystone_config('signing/key_size').with_value('2048')
      end
    end

    describe 'when configuring PKI signing cert paths with pki_setup disabled' do
      let :params do
        {
          'admin_token'          => 'service_token',
          'token_provider'       => 'keystone.token.providers.pki.Provider',
          'enable_pki_setup'     => false,
          'signing_certfile'     => 'signing_certfile',
          'signing_keyfile'      => 'signing_keyfile',
          'signing_ca_certs'     => 'signing_ca_certs',
          'signing_ca_key'       => 'signing_ca_key',
          'signing_cert_subject' => 'signing_cert_subject',
          'signing_key_size'     => 2048
        }
      end

      it { is_expected.to_not contain_exec('keystone-manage pki_setup') }

      it 'should contain correct PKI certfile config' do
        is_expected.to contain_keystone_config('signing/certfile').with_value('signing_certfile')
      end

      it 'should contain correct PKI keyfile config' do
        is_expected.to contain_keystone_config('signing/keyfile').with_value('signing_keyfile')
      end

      it 'should contain correct PKI ca_certs config' do
        is_expected.to contain_keystone_config('signing/ca_certs').with_value('signing_ca_certs')
      end

      it 'should contain correct PKI ca_key config' do
        is_expected.to contain_keystone_config('signing/ca_key').with_value('signing_ca_key')
      end

      it 'should contain correct PKI cert_subject config' do
        is_expected.to contain_keystone_config('signing/cert_subject').with_value('signing_cert_subject')
      end

      it 'should contain correct PKI key_size config' do
        is_expected.to contain_keystone_config('signing/key_size').with_value('2048')
      end
    end

    describe 'with invalid catalog_type' do
      let :params do
        { :admin_token  => 'service_token',
          :catalog_type => 'invalid' }
      end

      it_raises "a Puppet::Error", /validate_re\(\): "invalid" does not match "template|sql"/
    end

    describe 'when configuring catalog driver' do
      let :params do
        { :admin_token    => 'service_token',
          :catalog_driver => 'keystone.catalog.backends.alien.AlienCatalog' }
      end

      it { is_expected.to contain_keystone_config('catalog/driver').with_value(params[:catalog_driver]) }
    end
  end

  describe 'when configuring token expiration' do
    let :params do
      {
        'admin_token'      => 'service_token',
        'token_expiration' => '42',
      }
    end

    it { is_expected.to contain_keystone_config("token/expiration").with_value('42') }
  end

  describe 'when not configuring token expiration' do
    let :params do
      {
        'admin_token' => 'service_token',
      }
    end

    it { is_expected.to contain_keystone_config("token/expiration").with_value('3600') }
  end

  describe 'when sync_db is set to false' do
    let :params do
      {
        'admin_token' => 'service_token',
        'sync_db'     => false,
      }
    end

    it { is_expected.not_to contain_exec('keystone-manage db_sync') }
  end

  describe 'configure memcache servers if set' do
    let :params do
      {
        'admin_token'            => 'service_token',
        'memcache_servers'       => [ 'SERVER1:11211', 'SERVER2:11211' ],
        'token_driver'           => 'keystone.token.backends.memcache.Token',
        'cache_backend'          => 'dogpile.cache.memcached',
        'cache_backend_argument' => ['url:SERVER1:12211'],
      }
    end

    it { is_expected.to contain_keystone_config("memcache/servers").with_value('SERVER1:11211,SERVER2:11211') }
    it { is_expected.to contain_keystone_config('cache/enabled').with_value(true) }
    it { is_expected.to contain_keystone_config('token/caching').with_value(true) }
    it { is_expected.to contain_keystone_config('cache/backend').with_value('dogpile.cache.memcached') }
    it { is_expected.to contain_keystone_config('cache/backend_argument').with_value('url:SERVER1:12211') }
    it { is_expected.to contain_package('python-memcache').with(
      :name   => 'python-memcache',
      :ensure => 'present'
    ) }
  end

  describe 'do not configure memcache servers when not set' do
    let :params do
      default_params
    end

    it { is_expected.to contain_keystone_config("cache/enabled").with_ensure('absent') }
    it { is_expected.to contain_keystone_config("token/caching").with_ensure('absent') }
    it { is_expected.to contain_keystone_config("cache/backend").with_ensure('absent') }
    it { is_expected.to contain_keystone_config("cache/backend_argument").with_ensure('absent') }
    it { is_expected.to contain_keystone_config("cache/debug_cache_backend").with_ensure('absent') }
    it { is_expected.to contain_keystone_config("memcache/servers").with_ensure('absent') }
  end

  describe 'raise error if memcache_servers is not an array' do
    let :params do
      {
        'admin_token'      => 'service_token',
        'memcache_servers' => 'ANY_SERVER:11211'
      }
    end

    it { expect { is_expected.to contain_class('keystone::params') }.to \
      raise_error(Puppet::Error, /is not an Array/) }
  end

  describe 'with syslog disabled by default' do
    let :params do
      default_params
    end

    it { is_expected.to contain_keystone_config('DEFAULT/use_syslog').with_value(false) }
    it { is_expected.to_not contain_keystone_config('DEFAULT/syslog_log_facility') }
  end

  describe 'with syslog enabled' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { is_expected.to contain_keystone_config('DEFAULT/use_syslog').with_value(true) }
    it { is_expected.to contain_keystone_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
  end

  describe 'with syslog enabled and custom settings' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
        :log_facility => 'LOG_LOCAL0'
     })
    end

    it { is_expected.to contain_keystone_config('DEFAULT/use_syslog').with_value(true) }
    it { is_expected.to contain_keystone_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
  end

  describe 'with log_file disabled by default' do
    let :params do
      default_params
    end
    it { is_expected.to contain_keystone_config('DEFAULT/log_file').with_ensure('absent') }
  end

  describe 'with log_file and log_dir enabled' do
    let :params do
      default_params.merge({
        :log_file   => 'keystone.log',
        :log_dir    => '/var/lib/keystone'
     })
    end
    it { is_expected.to contain_keystone_config('DEFAULT/log_file').with_value('keystone.log') }
    it { is_expected.to contain_keystone_config('DEFAULT/log_dir').with_value('/var/lib/keystone') }
  end

    describe 'with log_file and log_dir disabled' do
    let :params do
      default_params.merge({
        :log_file   => false,
        :log_dir    => false
     })
    end
    it { is_expected.to contain_keystone_config('DEFAULT/log_file').with_ensure('absent') }
    it { is_expected.to contain_keystone_config('DEFAULT/log_dir').with_ensure('absent') }
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
    it {is_expected.to contain_keystone_config('ssl/enable').with_value(true)}
    it {is_expected.to contain_keystone_config('ssl/certfile').with_value('/etc/keystone/ssl/certs/keystone.pem')}
    it {is_expected.to contain_keystone_config('ssl/keyfile').with_value('/etc/keystone/ssl/private/keystonekey.pem')}
    it {is_expected.to contain_keystone_config('ssl/ca_certs').with_value('/etc/keystone/ssl/certs/ca.pem')}
    it {is_expected.to contain_keystone_config('ssl/ca_key').with_value('/etc/keystone/ssl/private/cakey.pem')}
    it {is_expected.to contain_keystone_config('ssl/cert_subject').with_value('/C=US/ST=Unset/L=Unset/O=Unset/CN=localhost')}
    it {is_expected.to contain_keystone_config('DEFAULT/public_endpoint').with_value('https://localhost:5000/v2.0/')}
    it {is_expected.to contain_keystone_config('DEFAULT/admin_endpoint').with_value('https://localhost:35357/v2.0/')}
  end
  describe 'when disabling SSL' do
    let :params do
      {
        'admin_token' => 'service_token',
        'enable_ssl'  => false,
      }
    end
    it {is_expected.to contain_keystone_config('ssl/enable').with_value(false)}
    it {is_expected.to contain_keystone_config('DEFAULT/public_endpoint').with_ensure('absent')}
    it {is_expected.to contain_keystone_config('DEFAULT/admin_endpoint').with_ensure('absent')}
  end
  describe 'not setting notification settings by default' do
    let :params do
      default_params
    end

    it { is_expected.to contain_keystone_config('DEFAULT/notification_driver').with_value(nil) }
    it { is_expected.to contain_keystone_config('DEFAULT/notification_topics').with_value(nil) }
    it { is_expected.to contain_keystone_config('DEFAULT/notification_format').with_value(nil) }
    it { is_expected.to contain_keystone_config('DEFAULT/control_exchange').with_value(nil) }
  end

  describe 'with RabbitMQ communication SSLed' do
    let :params do
      default_params.merge!({
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ssl/ca/certs',
        :kombu_ssl_certfile => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile',
        :kombu_ssl_version  => 'TLSv1'
      })
    end

    it do
      is_expected.to contain_keystone_config('DEFAULT/rabbit_use_ssl').with_value('true')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_ca_certs').with_value('/path/to/ssl/ca/certs')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_certfile').with_value('/path/to/ssl/cert/file')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_keyfile').with_value('/path/to/ssl/keyfile')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_version').with_value('TLSv1')
    end
  end

  describe 'with RabbitMQ communication not SSLed' do
    let :params do
      default_params.merge!({
        :rabbit_use_ssl     => false,
        :kombu_ssl_ca_certs => 'undef',
        :kombu_ssl_certfile => 'undef',
        :kombu_ssl_keyfile  => 'undef',
        :kombu_ssl_version  => 'TLSv1'
      })
    end

    it do
      is_expected.to contain_keystone_config('DEFAULT/rabbit_use_ssl').with_value('false')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_keystone_config('DEFAULT/kombu_ssl_version').with_ensure('absent')
    end
  end

  describe 'when configuring max_token_size' do
    let :params do
      default_params.merge({:max_token_size => '16384' })
    end

    it { is_expected.to contain_keystone_config('DEFAULT/max_token_size').with_value(params[:max_token_size]) }
  end

  describe 'setting notification settings' do
    let :params do
      default_params.merge({
        :notification_driver   => 'keystone.openstack.common.notifier.rpc_notifier',
        :notification_topics   => 'notifications',
        :notification_format   => 'cadf',
        :control_exchange      => 'keystone'
      })
    end

    it { is_expected.to contain_keystone_config('DEFAULT/notification_driver').with_value('keystone.openstack.common.notifier.rpc_notifier') }
    it { is_expected.to contain_keystone_config('DEFAULT/notification_topics').with_value('notifications') }
    it { is_expected.to contain_keystone_config('DEFAULT/notification_format').with_value('cadf') }
    it { is_expected.to contain_keystone_config('DEFAULT/control_exchange').with_value('keystone') }
  end

  describe 'setting sql (default) catalog' do
    let :params do
      default_params
    end

    it { is_expected.to contain_keystone_config('catalog/driver').with_value('keystone.catalog.backends.sql.Catalog') }
  end

  describe 'setting default template catalog' do
    let :params do
      {
        :admin_token    => 'service_token',
        :catalog_type   => 'template'
      }
    end

    it { is_expected.to contain_keystone_config('catalog/driver').with_value('keystone.catalog.backends.templated.Catalog') }
    it { is_expected.to contain_keystone_config('catalog/template_file').with_value('/etc/keystone/default_catalog.templates') }
  end

  describe 'with overridden validation_auth_url' do
    let :params do
      {
        :admin_token            => 'service_token',
        :validate_service       => true,
        :validate_auth_url      => 'http://some.host:35357/v2.0',
        :admin_endpoint         => 'http://some.host:35357'
      }
    end

    it { is_expected.to contain_keystone_config('DEFAULT/admin_endpoint').with_value('http://some.host:35357') }
    it { is_expected.to contain_class('keystone::service').with(
      'validate'       => true,
      'admin_endpoint' => 'http://some.host:35357/v2.0'
    )}
  end

  describe 'with service validation' do
    let :params do
      {
        :admin_token            => 'service_token',
        :validate_service       => true,
        :admin_endpoint         => 'http://some.host:35357'
      }
    end

    it { is_expected.to contain_class('keystone::service').with(
      'validate'       => true,
      'admin_endpoint' => 'http://some.host:35357'
    )}
  end

  describe 'setting another template catalog' do
    let :params do
      {
        :admin_token            => 'service_token',
        :catalog_type           => 'template',
        :catalog_template_file  => '/some/template_file'
      }
    end

    it { is_expected.to contain_keystone_config('catalog/driver').with_value('keystone.catalog.backends.templated.Catalog') }
    it { is_expected.to contain_keystone_config('catalog/template_file').with_value('/some/template_file') }
  end

  describe 'setting service_provider' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6.0'
      })
    end

    describe 'with default service_provider' do
      let :params do
        { 'admin_token'    => 'service_token' }
      end

      it { is_expected.to contain_service('keystone').with(
        :provider => nil
      )}
    end

    describe 'with overrided service_provider' do
      let :params do
        {
          'admin_token'      => 'service_token',
          'service_provider' => 'pacemaker'
        }
      end

      it { is_expected.to contain_service('keystone').with(
        :provider => 'pacemaker'
      )}
    end
  end

  describe 'when using fernet tokens' do
    describe 'when enabling fernet_setup' do
      let :params do
        default_params.merge({
          'enable_fernet_setup'    => true,
          'fernet_max_active_keys' => 5,
        })
      end

      it { is_expected.to contain_exec('keystone-manage fernet_setup').with(
        :creates => '/etc/keystone/fernet-keys/0'
      ) }
      it { is_expected.to contain_keystone_config('fernet_tokens/max_active_keys').with_value(5)}
    end

    describe 'when overriding the fernet key directory' do
      let :params do
        default_params.merge({
          'enable_fernet_setup'   => true,
          'fernet_key_repository' => '/var/lib/fernet-keys',
        })
      end
      it { is_expected.to contain_exec('keystone-manage fernet_setup').with(
        :creates => '/var/lib/fernet-keys/0'
      ) }

    end
  end

  describe 'when configuring paste_deploy' do
    describe 'with default paste config on Debian' do
      let :params do
        default_params
      end

      it { is_expected.to contain_keystone_config('paste_deploy/config_file').with_ensure('absent')}
    end

    describe 'with default paste config on RedHat' do
      let :facts do
        global_facts.merge({
          :osfamily               => 'RedHat',
          :operatingsystemrelease => '6.0'
        })
      end
      let :params do
        default_params
      end

      it { is_expected.to contain_keystone_config('paste_deploy/config_file').with_value(
          '/usr/share/keystone/keystone-dist-paste.ini'
      )}
    end

    describe 'with overrided paste_deploy' do
      let :params do
        default_params.merge({
          'paste_config'    => '/usr/share/keystone/keystone-paste.ini',
        })
      end

      it { is_expected.to contain_keystone_config('paste_deploy/config_file').with_value(
          '/usr/share/keystone/keystone-paste.ini'
      )}
    end
  end

  context 'on RedHat platforms' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '7.0'
      })
    end

    let :platform_parameters do
      {
        :service_name => 'openstack-keystone'
      }
    end

    it_configures 'when using default class parameters for httpd'
  end

  context 'on Debian platforms' do
    let :facts do
      global_facts.merge({
        :osfamily               => 'Debian',
        :operatingsystem        => 'Debian',
        :operatingsystemrelease => '7.0'
      })
    end

    let :platform_parameters do
      {
        :service_name => 'keystone'
      }
    end

    it_configures 'when using default class parameters for httpd'
  end
end
