require 'spec_helper'

describe 'neutron' do

  let :params do
    { :package_ensure        => 'present',
      :verbose               => false,
      :debug                 => false,
      :core_plugin           => 'linuxbridge',
      :rabbit_host           => '127.0.0.1',
      :rabbit_port           => 5672,
      :rabbit_hosts          => false,
      :rabbit_user           => 'guest',
      :rabbit_password       => 'guest',
      :rabbit_virtual_host   => '/',
      :kombu_reconnect_delay => '1.0',
      :log_dir               => '/var/log/neutron',
      :report_interval       => '30',
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'neutron' do

    context 'and if rabbit_host parameter is provided' do
      it_configures 'a neutron base installation'
    end

    context 'and if rabbit_hosts parameter is provided' do
      before do
        params.delete(:rabbit_host)
        params.delete(:rabbit_port)
      end

      context 'with one server' do
        before { params.merge!( :rabbit_hosts => ['127.0.0.1:5672'] ) }
        it_configures 'a neutron base installation'
        it_configures 'rabbit HA with a single virtual host'
      end

      context 'with multiple servers' do
        before { params.merge!( :rabbit_hosts => ['rabbit1:5672', 'rabbit2:5672'] ) }
        it_configures 'a neutron base installation'
        it_configures 'rabbit HA with multiple hosts'
      end

      it 'configures logging' do
        is_expected.to contain_neutron_config('DEFAULT/log_file').with_ensure('absent')
        is_expected.to contain_neutron_config('DEFAULT/log_dir').with_value(params[:log_dir])
      end

    end

    it_configures 'with SSL enabled with kombu'
    it_configures 'with SSL enabled without kombu'
    it_configures 'with SSL disabled'
    it_configures 'with SSL wrongly configured'
    it_configures 'with SSL and kombu wrongly configured'
    it_configures 'with SSL socket options set'
    it_configures 'with SSL socket options set with wrong parameters'
    it_configures 'with SSL socket options set to false'
    it_configures 'with syslog disabled'
    it_configures 'with syslog enabled'
    it_configures 'with syslog enabled and custom settings'
    it_configures 'with log_file specified'
    it_configures 'with logging disabled'
    it_configures 'without service_plugins'
    it_configures 'with service_plugins'
    it_configures 'without memcache_servers'
    it_configures 'with memcache_servers'
  end

  shared_examples_for 'a neutron base installation' do

    it { is_expected.to contain_class('neutron::params') }

    it 'configures neutron configuration folder' do
      is_expected.to contain_file('/etc/neutron/').with(
        :ensure  => 'directory',
        :owner   => 'root',
        :group   => 'neutron',
        :require => 'Package[neutron]'
      )
    end

    it 'configures neutron configuration file' do
      is_expected.to contain_file('/etc/neutron/neutron.conf').with(
        :owner   => 'root',
        :group   => 'neutron',
        :require => 'Package[neutron]'
      )
    end

    it 'installs neutron package' do
      is_expected.to contain_package('neutron').with(
        :ensure => 'present',
        :name   => platform_params[:common_package_name],
        :tag    => 'openstack'
      )
    end

    it 'configures credentials for rabbit' do
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_userid').with_value( params[:rabbit_user] )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_password').with_value( params[:rabbit_password] )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_password').with_secret( true )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_virtual_host').with_value( params[:rabbit_virtual_host] )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_reconnect_delay').with_value( params[:kombu_reconnect_delay] )
    end

    it 'configures neutron.conf' do
      is_expected.to contain_neutron_config('DEFAULT/verbose').with_value( params[:verbose] )
      is_expected.to contain_neutron_config('DEFAULT/bind_host').with_value('0.0.0.0')
      is_expected.to contain_neutron_config('DEFAULT/bind_port').with_value('9696')
      is_expected.to contain_neutron_config('DEFAULT/auth_strategy').with_value('keystone')
      is_expected.to contain_neutron_config('DEFAULT/core_plugin').with_value( params[:core_plugin] )
      is_expected.to contain_neutron_config('DEFAULT/base_mac').with_value('fa:16:3e:00:00:00')
      is_expected.to contain_neutron_config('DEFAULT/mac_generation_retries').with_value(16)
      is_expected.to contain_neutron_config('DEFAULT/dhcp_lease_duration').with_value(86400)
      is_expected.to contain_neutron_config('DEFAULT/dhcp_agents_per_network').with_value(1)
      is_expected.to contain_neutron_config('DEFAULT/network_device_mtu').with_ensure('absent')
      is_expected.to contain_neutron_config('DEFAULT/dhcp_agent_notification').with_value(true)
      is_expected.to contain_neutron_config('DEFAULT/allow_bulk').with_value(true)
      is_expected.to contain_neutron_config('DEFAULT/allow_pagination').with_value(false)
      is_expected.to contain_neutron_config('DEFAULT/allow_sorting').with_value(false)
      is_expected.to contain_neutron_config('DEFAULT/allow_overlapping_ips').with_value(false)
      is_expected.to contain_neutron_config('DEFAULT/api_extensions_path').with_value(nil)
      is_expected.to contain_neutron_config('DEFAULT/control_exchange').with_value('neutron')
      is_expected.to contain_neutron_config('DEFAULT/state_path').with_value('/var/lib/neutron')
      is_expected.to contain_neutron_config('DEFAULT/lock_path').with_value('/var/lib/neutron/lock')
      is_expected.to contain_neutron_config('agent/root_helper').with_value('sudo neutron-rootwrap /etc/neutron/rootwrap.conf')
      is_expected.to contain_neutron_config('agent/report_interval').with_value('30')
    end
  end

  shared_examples_for 'rabbit HA with a single virtual host' do
    it 'in neutron.conf' do
      is_expected.not_to contain_neutron_config('oslo_messaging_rabbit/rabbit_host')
      is_expected.not_to contain_neutron_config('oslo_messaging_rabbit/rabbit_port')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts] )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
    end
  end

  shared_examples_for 'rabbit HA with multiple hosts' do
    it 'in neutron.conf' do
      is_expected.not_to contain_neutron_config('oslo_messaging_rabbit/rabbit_host')
      is_expected.not_to contain_neutron_config('oslo_messaging_rabbit/rabbit_port')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_hosts').with_value( params[:rabbit_hosts].join(',') )
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_ha_queues').with_value(true)
    end
  end

  shared_examples_for 'with SSL socket options set' do
    before do
      params.merge!(
        :use_ssl         => true,
        :cert_file       => '/path/to/cert',
        :key_file        => '/path/to/key',
        :ca_file         => '/path/to/ca'
      )
    end

    it { is_expected.to contain_neutron_config('DEFAULT/use_ssl').with_value('true') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_cert_file').with_value('/path/to/cert') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_key_file').with_value('/path/to/key') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_ca_file').with_value('/path/to/ca') }
  end

  shared_examples_for 'with SSL socket options set with wrong parameters' do
    before do
      params.merge!(
        :use_ssl         => true,
        :key_file        => '/path/to/key',
        :ca_file         => '/path/to/ca'
      )
    end

    it_raises 'a Puppet::Error', /The cert_file parameter is required when use_ssl is set to true/
  end

  shared_examples_for 'with SSL socket options set to false' do
    before do
      params.merge!(
        :use_ssl         => false,
        :cert_file       => false,
        :key_file        => false,
        :ca_file         => false
      )
    end

    it { is_expected.to contain_neutron_config('DEFAULT/use_ssl').with_value('false') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_cert_file').with_ensure('absent') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_key_file').with_ensure('absent') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_ca_file').with_ensure('absent') }
  end

  shared_examples_for 'with SSL socket options set and no ca_file' do
    before do
      params.merge!(
        :use_ssl         => true,
        :cert_file       => '/path/to/cert',
        :key_file        => '/path/to/key'
      )
    end

    it { is_expected.to contain_neutron_config('DEFAULT/use_ssl').with_value('true') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_cert_file').with_value('/path/to/cert') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_key_file').with_value('/path/to/key') }
    it { is_expected.to contain_neutron_config('DEFAULT/ssl_ca_file').with_ensure('absent') }
  end

  shared_examples_for 'with SSL socket options disabled with ca_file' do
    before do
      params.merge!(
        :use_ssl         => false,
        :ca_file         => '/path/to/ca'
      )
    end

    it_raises 'a Puppet::Error', /The ca_file parameter requires that use_ssl to be set to true/
  end

  shared_examples_for 'with syslog disabled' do
    it { is_expected.to contain_neutron_config('DEFAULT/use_syslog').with_value(false) }
  end

  shared_examples_for 'with SSL enabled with kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_ca_certs => '/path/to/ssl/ca/certs',
        :kombu_ssl_certfile => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile',
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_value('/path/to/ssl/ca/certs')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_value('/path/to/ssl/cert/file')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_value('/path/to/ssl/keyfile')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL enabled without kombu' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true
      )
    end

    it do
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('true')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_version').with_value('TLSv1')
    end
  end

  shared_examples_for 'with SSL disabled' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false,
        :kombu_ssl_version  => 'TLSv1'
      )
    end

    it do
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/rabbit_use_ssl').with_value('false')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_ca_certs').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_certfile').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_keyfile').with_ensure('absent')
      is_expected.to contain_neutron_config('oslo_messaging_rabbit/kombu_ssl_version').with_ensure('absent')
    end
  end

  shared_examples_for 'with SSL wrongly configured' do
    before do
      params.merge!(
        :rabbit_use_ssl     => false
      )
    end

    context 'with SSL disabled' do

      context 'with kombu_ssl_ca_certs parameter' do
        before { params.merge!(:kombu_ssl_ca_certs => '/path/to/ssl/ca/certs') }
        it_raises 'a Puppet::Error', /The kombu_ssl_ca_certs parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_certfile parameter' do
        before { params.merge!(:kombu_ssl_certfile => '/path/to/ssl/cert/file') }
        it_raises 'a Puppet::Error', /The kombu_ssl_certfile parameter requires rabbit_use_ssl to be set to true/
      end

      context 'with kombu_ssl_keyfile parameter' do
        before { params.merge!(:kombu_ssl_keyfile => '/path/to/ssl/keyfile') }
        it_raises 'a Puppet::Error', /The kombu_ssl_keyfile parameter requires rabbit_use_ssl to be set to true/
      end
    end

  end

  shared_examples_for 'with SSL and kombu wrongly configured' do
    before do
      params.merge!(
        :rabbit_use_ssl     => true,
        :kombu_ssl_certfile  => '/path/to/ssl/cert/file',
        :kombu_ssl_keyfile  => '/path/to/ssl/keyfile'
      )
    end

    context 'without required parameters' do

      context 'without kombu_ssl_keyfile parameter' do
        before { params.delete(:kombu_ssl_keyfile) }
        it_raises 'a Puppet::Error', /The kombu_ssl_certfile and kombu_ssl_keyfile parameters must be used together/
      end
    end

  end

  shared_examples_for 'with syslog enabled' do
    before do
      params.merge!(
        :use_syslog => 'true'
      )
    end

    it do
      is_expected.to contain_neutron_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_neutron_config('DEFAULT/syslog_log_facility').with_value('LOG_USER')
    end
  end

  shared_examples_for 'with syslog enabled and custom settings' do
    before do
      params.merge!(
        :use_syslog    => 'true',
        :log_facility  => 'LOG_LOCAL0'
      )
    end

    it do
      is_expected.to contain_neutron_config('DEFAULT/use_syslog').with_value(true)
      is_expected.to contain_neutron_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0')
    end
  end

  shared_examples_for 'with log_file specified' do
    before do
      params.merge!(
        :log_file => '/var/log/neutron/server.log',
        :log_dir  => '/tmp/log/neutron'
      )
    end
    it 'configures logging' do
      is_expected.to contain_neutron_config('DEFAULT/log_file').with_value(params[:log_file])
      is_expected.to contain_neutron_config('DEFAULT/log_dir').with_value(params[:log_dir])
    end
  end

  shared_examples_for 'with logging disabled' do
    before { params.merge!(
      :log_file => false,
      :log_dir  => false
    )}
    it {
      is_expected.to contain_neutron_config('DEFAULT/log_file').with_ensure('absent')
      is_expected.to contain_neutron_config('DEFAULT/log_dir').with_ensure('absent')
    }
  end

  shared_examples_for 'with state and lock paths set' do
    before { params.merge!(
      :state_path => 'state_path',
      :lock_path  => 'lock_path'
    )}
    it {
      is_expected.to contain_neutron_config('DEFAULT/state_path').with_value('state_path')
      is_expected.to contain_neutron_config('DEFAULT/lock_path').with_value('lock_path')
    }
  end

  shared_examples_for 'without service_plugins' do
    it { is_expected.not_to contain_neutron_config('DEFAULT/service_plugins') }
  end

  shared_examples_for 'with service_plugins' do
    before do
      params.merge!(
        :service_plugins => ['router','firewall','lbaas','vpnaas','metering']
      )
    end

    it do
      is_expected.to contain_neutron_config('DEFAULT/service_plugins').with_value('router,firewall,lbaas,vpnaas,metering')
    end

  end

  shared_examples_for 'without memcache_servers' do
    it { is_expected.to contain_neutron_config('DEFAULT/memcached_servers').with_ensure('absent') }
  end

  shared_examples_for 'with memcache_servers' do
    before do
      params.merge!(
        :memcache_servers => ['memcache1','memcache2','memcache3']
      )
    end

    it do
      is_expected.to contain_neutron_config('DEFAULT/memcached_servers').with_value('memcache1,memcache2,memcache3')
    end

  end

  shared_examples_for 'with network_device_mtu defined' do
    before do
      params.merge!(
        :network_device_mtu => 9000
      )
    end

    it do
      is_expected.to contain_neutron_config('DEFAULT/network_device_mtu').with_value(params[:network_device_mtu])
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :common_package_name => 'neutron-common' }
    end

    it_configures 'neutron'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :common_package_name => 'openstack-neutron' }
    end

    it_configures 'neutron'
  end
end
