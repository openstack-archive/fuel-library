
describe 'glance::registry' do

  let :facts do
    {
      :osfamily => 'Debian'
    }
  end

  let :default_params do
    {
      :verbose                => false,
      :debug                  => false,
      :bind_host              => '0.0.0.0',
      :bind_port              => '9191',
      :log_file               => '/var/log/glance/registry.log',
      :log_dir                => '/var/log/glance',
      :database_connection    => 'sqlite:///var/lib/glance/glance.sqlite',
      :database_idle_timeout  => '3600',
      :enabled                => true,
      :manage_service         => true,
      :auth_type              => 'keystone',
      :auth_host              => '127.0.0.1',
      :auth_port              => '35357',
      :auth_protocol          => 'http',
      :auth_uri               => 'http://127.0.0.1:5000/',
      :keystone_tenant        => 'services',
      :keystone_user          => 'glance',
      :keystone_password      => 'ChangeMe',
      :purge_config           => false,
      :sync_db                => true,
    }
  end

  [
    {:keystone_password => 'ChangeMe'},
    {
      :verbose                => true,
      :debug                  => true,
      :bind_host              => '127.0.0.1',
      :bind_port              => '9111',
      :database_connection    => 'sqlite:///var/lib/glance.sqlite',
      :database_idle_timeout  => '360',
      :enabled                => false,
      :auth_type              => 'keystone',
      :auth_host              => '127.0.0.1',
      :auth_port              => '35357',
      :auth_protocol          => 'http',
      :auth_uri               => 'http://127.0.0.1:5000/',
      :keystone_tenant        => 'admin',
      :keystone_user          => 'admin',
      :keystone_password      => 'ChangeMe',
      :sync_db                => false,
    }
  ].each do |param_set|

    describe "when #{param_set == {:keystone_password => 'ChangeMe'} ? "using default" : "specifying"} class parameters" do
      let :param_hash do
        default_params.merge(param_set)
      end

      let :params do
        param_set
      end

      it { is_expected.to contain_class 'glance::registry' }

      it { is_expected.to contain_service('glance-registry').with(
          'ensure'     => (param_hash[:manage_service] && param_hash[:enabled]) ? 'running' : 'stopped',
          'enable'     => param_hash[:enabled],
          'hasstatus'  => true,
          'hasrestart' => true,
          'subscribe'  => 'File[/etc/glance/glance-registry.conf]',
          'require'    => 'Class[Glance]'
      )}

      it 'is_expected.to only sync the db if sync_db is enabled' do

        if param_hash[:sync_db]
          is_expected.to contain_exec('glance-manage db_sync').with(
            'path'        => '/usr/bin',
            'command'     => 'glance-manage --config-file=/etc/glance/glance-registry.conf db_sync',
            'refreshonly' => true,
            'logoutput'   => 'on_failure',
            'subscribe'   => ['Package[glance-registry]', 'File[/etc/glance/glance-registry.conf]'],
            'notify'      => ["Service[glance-registry]"]
          )
        end
      end
      it 'is_expected.to not sync the db if sync_db is set to false' do

        if !param_hash[:sync_db]
          is_expected.not_to contain_exec('glance-manage db_sync')
        end
      end
      it 'is_expected.to configure itself' do
        [
         'verbose',
         'debug',
         'bind_port',
         'bind_host',
        ].each do |config|
          is_expected.to contain_glance_registry_config("DEFAULT/#{config}").with_value(param_hash[config.intern])
        end
        [
         'database_connection',
         'database_idle_timeout',
        ].each do |config|
          is_expected.to contain_glance_registry_config("database/#{config.gsub(/database_/,'')}").with_value(param_hash[config.intern])
        end
        [
         'auth_host',
         'auth_port',
         'auth_protocol'
        ].each do |config|
          is_expected.to contain_glance_registry_config("keystone_authtoken/#{config}").with_value(param_hash[config.intern])
        end
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_admin_prefix').with_ensure('absent')
        if param_hash[:auth_type] == 'keystone'
          is_expected.to contain_glance_registry_config("paste_deploy/flavor").with_value('keystone')
          is_expected.to contain_glance_registry_config("keystone_authtoken/admin_tenant_name").with_value(param_hash[:keystone_tenant])
          is_expected.to contain_glance_registry_config("keystone_authtoken/admin_user").with_value(param_hash[:keystone_user])
          is_expected.to contain_glance_registry_config("keystone_authtoken/admin_password").with_value(param_hash[:keystone_password])
          is_expected.to contain_glance_registry_config("keystone_authtoken/admin_password").with_value(param_hash[:keystone_password]).with_secret(true)
        end
      end
    end
  end

  describe 'with disabled service managing' do
    let :params do
      {
        :keystone_password => 'ChangeMe',
        :manage_service => false,
        :enabled        => false,
      }
    end

    it { is_expected.to contain_service('glance-registry').with(
          'ensure'     => nil,
          'enable'     => false,
          'hasstatus'  => true,
          'hasrestart' => true,
          'subscribe'  => 'File[/etc/glance/glance-registry.conf]',
          'require'    => 'Class[Glance]'
      )}
  end

  describe 'with overridden pipeline' do
    # At the time of writing there was only blank and keystone as options
    # but there is no reason that there can't be more options in the future.
    let :params do
      {
        :keystone_password => 'ChangeMe',
        :pipeline          => 'validoptionstring',
      }
    end

    it { is_expected.to contain_glance_registry_config('paste_deploy/flavor').with_value('validoptionstring') }
  end

  describe 'with blank pipeline' do
    let :params do
      {
        :keystone_password => 'ChangeMe',
        :pipeline          => '',
      }
    end

    it { is_expected.to contain_glance_registry_config('paste_deploy/flavor').with_ensure('absent') }
  end

  [
    'keystone/',
    'keystone+',
    '+keystone',
    'keystone+cachemanagement+',
    '+'
  ].each do |pipeline|
    describe "with pipeline incorrect value #{pipeline}" do
      let :params do
        {
          :keystone_password => 'ChangeMe',
          :auth_type         => 'keystone',
          :pipeline          => pipeline
        }
      end

      it { expect { is_expected.to contain_glance_registry_config('filter:paste_deploy/flavor') }.to\
        raise_error(Puppet::Error, /validate_re\(\): .* does not match/) }
    end
  end

  describe 'with overriden auth_admin_prefix' do
    let :params do
      {
        :keystone_password => 'ChangeMe',
        :auth_admin_prefix => '/keystone/main'
      }
    end

    it { is_expected.to contain_glance_registry_config('keystone_authtoken/auth_admin_prefix').with_value('/keystone/main') }
  end

  [
    '/keystone/',
    'keystone/',
    'keystone',
    '/keystone/admin/',
    'keystone/admin/',
    'keystone/admin'
  ].each do |auth_admin_prefix|
    describe "with auth_admin_prefix_containing incorrect value #{auth_admin_prefix}" do
      let :params do
        {
          :keystone_password => 'ChangeMe',
          :auth_admin_prefix => auth_admin_prefix
        }
      end

      it { expect { is_expected.to contain_glance_registry_config('filter:authtoken/auth_admin_prefix') }.to\
        raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/) }
    end
  end

  describe 'with syslog disabled by default' do
    let :params do
      default_params
    end

    it { is_expected.to contain_glance_registry_config('DEFAULT/use_syslog').with_value(false) }
    it { is_expected.to_not contain_glance_registry_config('DEFAULT/syslog_log_facility') }
  end

  describe 'with syslog enabled' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
      })
    end

    it { is_expected.to contain_glance_registry_config('DEFAULT/use_syslog').with_value(true) }
    it { is_expected.to contain_glance_registry_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
  end

  describe 'with syslog enabled and custom settings' do
    let :params do
      default_params.merge({
        :use_syslog   => 'true',
        :log_facility => 'LOG_LOCAL0'
     })
    end

    it { is_expected.to contain_glance_registry_config('DEFAULT/use_syslog').with_value(true) }
    it { is_expected.to contain_glance_registry_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
  end

  describe 'with log_file enabled by default' do
    let(:params) { default_params }

    it { is_expected.to contain_glance_registry_config('DEFAULT/log_file').with_value(default_params[:log_file]) }

    context 'with log_file disabled' do
      let(:params) { default_params.merge!({ :log_file => false }) }
      it { is_expected.to contain_glance_registry_config('DEFAULT/log_file').with_ensure('absent') }
    end
  end

  describe 'with log_dir enabled by default' do
    let(:params) { default_params }

    it { is_expected.to contain_glance_registry_config('DEFAULT/log_dir').with_value(default_params[:log_dir]) }

    context 'with log_dir disabled' do
      let(:params) { default_params.merge!({ :log_dir => false }) }
      it { is_expected.to contain_glance_registry_config('DEFAULT/log_dir').with_ensure('absent') }
    end
  end

  describe 'with no ssl options (default)' do
    let(:params) { default_params }

    it { is_expected.to contain_glance_registry_config('DEFAULT/ca_file').with_ensure('absent')}
    it { is_expected.to contain_glance_registry_config('DEFAULT/cert_file').with_ensure('absent')}
    it { is_expected.to contain_glance_registry_config('DEFAULT/key_file').with_ensure('absent')}
  end

  describe 'with ssl options' do
    let :params do
      default_params.merge({
        :ca_file     => '/tmp/ca_file',
        :cert_file   => '/tmp/cert_file',
        :key_file    => '/tmp/key_file'
      })
    end

    context 'with ssl options' do
      it { is_expected.to contain_glance_registry_config('DEFAULT/ca_file').with_value('/tmp/ca_file') }
      it { is_expected.to contain_glance_registry_config('DEFAULT/cert_file').with_value('/tmp/cert_file') }
      it { is_expected.to contain_glance_registry_config('DEFAULT/key_file').with_value('/tmp/key_file') }
    end
  end


  describe 'with identity and auth settings' do
    let :params do
      {
        :keystone_password => 'ChangeMe',
      }
    end
    context 'with custom keystone identity_uri' do
      before do
        params.merge!({
          :identity_uri => 'https://foo.bar:1234/',
        })
      end
      it 'configures identity_uri' do
        is_expected.to contain_glance_registry_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:1234/");
        # since only auth_uri is set the deprecated auth parameters is_expected.to
        # still get set in case they are still in use
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_host').with_value('127.0.0.1');
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_port').with_value('35357');
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_protocol').with_value('http');
      end
    end

    context 'with custom keystone identity_uri and auth_uri' do
      before do
        params.merge!({
          :identity_uri => 'https://foo.bar:35357/',
          :auth_uri => 'https://foo.bar:5000/v2.0/',
        })
      end
      it 'configures identity_uri' do
        is_expected.to contain_glance_registry_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:35357/");
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_uri').with_value("https://foo.bar:5000/v2.0/");
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_host').with_ensure('absent')
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_port').with_ensure('absent')
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_protocol').with_ensure('absent')
        is_expected.to contain_glance_registry_config('keystone_authtoken/auth_admin_prefix').with_ensure('absent')
      end
    end
  end

  describe 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    # We only test this on Debian platforms, since on RedHat there isn't a
    # separate package for glance registry.
    ['present', 'latest'].each do |package_ensure|
      context "with package_ensure '#{package_ensure}'" do
        let(:params) { default_params.merge({ :package_ensure => package_ensure }) }
        it { is_expected.to contain_package('glance-registry').with(
            :ensure => package_ensure,
            :tag    => ['openstack']
        )}
      end
    end
  end

  describe 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    let(:params) { default_params }

    it { is_expected.to contain_package('openstack-glance')}
  end

  describe 'on unknown platforms' do
    let :facts do
      { :osfamily => 'unknown' }
    end
    let(:params) { default_params }

    it_raises 'a Puppet::Error', /module glance only support osfamily RedHat and Debian/
  end

end
