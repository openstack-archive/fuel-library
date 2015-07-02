require 'spec_helper'

describe 'neutron::server' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    { :auth_password => 'passw0rd',
      :auth_user     => 'neutron' }
  end

  let :default_params do
    { :package_ensure                   => 'present',
      :enabled                          => true,
      :auth_type                        => 'keystone',
      :auth_host                        => 'localhost',
      :auth_port                        => '35357',
      :auth_tenant                      => 'services',
      :auth_user                        => 'neutron',
      :database_connection              => 'sqlite:////var/lib/neutron/ovs.sqlite',
      :database_max_retries             => 10,
      :database_idle_timeout            => 3600,
      :database_retry_interval          => 10,
      :database_min_pool_size           => 1,
      :database_max_pool_size           => 10,
      :database_max_overflow            => 20,
      :sync_db                          => false,
      :agent_down_time                  => 75,
      :router_scheduler_driver          => 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
      :router_distributed               => false,
      :l3_ha                            => false,
      :max_l3_agents_per_router         => 3,
      :min_l3_agents_per_router         => 2,
      :l3_ha_net_cidr                   => '169.254.192.0/18',
      :allow_automatic_l3agent_failover => false
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'a neutron server' do
    let :p do
      default_params.merge(params)
    end

    it 'should perform default database configuration of' do
      is_expected.to contain_neutron_config('database/connection').with_value(p[:database_connection])
      is_expected.to contain_neutron_config('database/connection').with_secret( true )
      is_expected.to contain_neutron_config('database/max_retries').with_value(p[:database_max_retries])
      is_expected.to contain_neutron_config('database/idle_timeout').with_value(p[:database_idle_timeout])
      is_expected.to contain_neutron_config('database/retry_interval').with_value(p[:database_retry_interval])
      is_expected.to contain_neutron_config('database/min_pool_size').with_value(p[:database_min_pool_size])
      is_expected.to contain_neutron_config('database/max_pool_size').with_value(p[:database_max_pool_size])
      is_expected.to contain_neutron_config('database/max_overflow').with_value(p[:database_max_overflow])
    end

    it { is_expected.to contain_class('neutron::params') }
    it { is_expected.to contain_class('neutron::policy') }

    it 'configures authentication middleware' do
      is_expected.to contain_neutron_api_config('filter:authtoken/auth_host').with_value(p[:auth_host]);
      is_expected.to contain_neutron_api_config('filter:authtoken/auth_port').with_value(p[:auth_port]);
      is_expected.to contain_neutron_api_config('filter:authtoken/admin_tenant_name').with_value(p[:auth_tenant]);
      is_expected.to contain_neutron_api_config('filter:authtoken/admin_user').with_value(p[:auth_user]);
      is_expected.to contain_neutron_api_config('filter:authtoken/admin_password').with_value(p[:auth_password]);
      is_expected.to contain_neutron_api_config('filter:authtoken/admin_password').with_secret( true )
      is_expected.to contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(:ensure => 'absent')
      is_expected.to contain_neutron_api_config('filter:authtoken/auth_uri').with_value("http://localhost:5000/");
    end

    it 'installs neutron server package' do
      if platform_params.has_key?(:server_package)
        is_expected.to contain_package('neutron-server').with(
          :name   => platform_params[:server_package],
          :ensure => p[:package_ensure],
          :tag    => 'openstack'
        )
        is_expected.to contain_package('neutron-server').with_before(/Neutron_api_config\[.+\]/)
        is_expected.to contain_package('neutron-server').with_before(/Neutron_config\[.+\]/)
        is_expected.to contain_package('neutron-server').with_before(/Service\[neutron-server\]/)
      else
        is_expected.to contain_package('neutron').with_before(/Neutron_api_config\[.+\]/)
      end
    end

    it 'configures neutron server service' do
      is_expected.to contain_service('neutron-server').with(
        :name    => platform_params[:server_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
      is_expected.not_to contain_exec('neutron-db-sync')
      is_expected.to contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(
        :ensure => 'absent'
      )
      is_expected.to contain_service('neutron-server').with_name('neutron-server')
      is_expected.to contain_neutron_config('DEFAULT/api_workers').with_value(facts[:processorcount])
      is_expected.to contain_neutron_config('DEFAULT/rpc_workers').with_value(facts[:processorcount])
      is_expected.to contain_neutron_config('DEFAULT/agent_down_time').with_value(p[:agent_down_time])
      is_expected.to contain_neutron_config('DEFAULT/router_scheduler_driver').with_value(p[:router_scheduler_driver])
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        is_expected.to contain_service('neutron-server').without_ensure
      end
    end

    context 'with DVR enabled' do
      before :each do
        params.merge!(:router_distributed => true)
      end
      it 'should enable DVR' do
        is_expected.to contain_neutron_config('DEFAULT/router_distributed').with_value(true)
      end
    end

    context 'with HA routers enabled' do
      before :each do
        params.merge!(:l3_ha => true)
      end
      it 'should enable HA routers' do
        is_expected.to contain_neutron_config('DEFAULT/l3_ha').with_value(true)
        is_expected.to contain_neutron_config('DEFAULT/max_l3_agents_per_router').with_value(3)
        is_expected.to contain_neutron_config('DEFAULT/min_l3_agents_per_router').with_value(2)
        is_expected.to contain_neutron_config('DEFAULT/l3_ha_net_cidr').with_value('169.254.192.0/18')
      end
    end

    context 'with HA routers disabled' do
      before :each do
        params.merge!(:l3_ha => false)
      end
      it 'should disable HA routers' do
        is_expected.to contain_neutron_config('DEFAULT/l3_ha').with_value(false)
      end
    end

    context 'with HA routers enabled with unlimited l3 agents per router' do
      before :each do
        params.merge!(:l3_ha                    => true,
                      :max_l3_agents_per_router => 0 )
      end
      it 'should enable HA routers' do
        is_expected.to contain_neutron_config('DEFAULT/max_l3_agents_per_router').with_value(0)
      end
    end

    context 'with HA routers enabled and wrong parameters' do
      before :each do
        params.merge!(:l3_ha                    => true,
                      :max_l3_agents_per_router => 2,
                      :min_l3_agents_per_router => 3 )
      end

      it_raises 'a Puppet::Error', /min_l3_agents_per_router should be less than or equal to max_l3_agents_per_router./
    end

    context 'with custom service name' do
      before :each do
        params.merge!(:service_name => 'custom-service-name')
      end
      it 'should configure proper service name' do
        is_expected.to contain_service('neutron-server').with_name('custom-service-name')
      end
    end

    context 'with state_path and lock_path parameters' do
      before :each do
        params.merge!(:state_path => 'state_path',
                      :lock_path  => 'lock_path' )
      end
      it 'should override state_path and lock_path from base class' do
        is_expected.to contain_neutron_config('DEFAULT/state_path').with_value(p[:state_path])
        is_expected.to contain_neutron_config('DEFAULT/lock_path').with_value(p[:lock_path])
      end
    end

    context 'with allow_automatic_l3agent_failover in neutron.conf' do
      it 'should configure allow_automatic_l3agent_failover' do
        is_expected.to contain_neutron_config('DEFAULT/allow_automatic_l3agent_failover').with_value(p[:allow_automatic_l3agent_failover])
      end
    end
  end

  shared_examples_for 'a neutron server with auth_admin_prefix set' do
    [ '/keystone', '/keystone/admin' ].each do |auth_admin_prefix|
      describe "with keystone_auth_admin_prefix containing incorrect value #{auth_admin_prefix}" do
        before do
          params.merge!({
            :auth_admin_prefix => auth_admin_prefix,
          })
        end
        it do
          is_expected.to contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(
            :value => params[:auth_admin_prefix]
          )
        end
      end
    end
  end

  shared_examples_for 'a neutron server with some incorrect auth_admin_prefix set' do
    [ '/keystone/', 'keystone/', 'keystone' ].each do |auth_admin_prefix|
      describe "with keystone_auth_admin_prefix containing incorrect value #{auth_admin_prefix}" do
        before do
          params.merge!({
            :auth_admin_prefix => auth_admin_prefix,
          })
        end
        it_raises 'a Puppet::Error', /validate_re\(\): "#{auth_admin_prefix}" does not match/
      end
    end
  end

  shared_examples_for 'a neutron server with broken authentication' do
    before do
      params.delete(:auth_password)
    end
    it_raises 'a Puppet::Error', /auth_password must be set/
  end

  shared_examples_for 'a neutron server without database synchronization' do
    before do
      params.merge!(
        :sync_db => true
      )
    end
    it 'should exec neutron-db-sync' do
      is_expected.to contain_exec('neutron-db-sync').with(
        :command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
        :path        => '/usr/bin',
        :before      => 'Service[neutron-server]',
        :subscribe   => 'Neutron_config[database/connection]',
        :refreshonly => true
      )
    end
  end

  shared_examples_for 'a neutron server with database_connection specified' do
    before do
      params.merge!(
        :database_connection => 'sqlite:////var/lib/neutron/ovs-TEST_parameter.sqlite'
      )
    end
    it 'configures database connection' do
      is_expected.to contain_neutron_config('database/connection').with_value(params[:database_connection])
    end
  end

  describe "with custom keystone auth_uri" do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end
    before do
      params.merge!({
        :auth_uri => 'https://foo.bar:1234/',
      })
    end
    it 'configures auth_uri' do
      is_expected.to contain_neutron_config('keystone_authtoken/auth_uri').with_value("https://foo.bar:1234/");
      # since only auth_uri is set the deprecated auth parameters should
      # still get set in case they are still in use
      is_expected.to contain_neutron_config('keystone_authtoken/auth_host').with_value('localhost');
      is_expected.to contain_neutron_config('keystone_authtoken/auth_port').with_value('35357');
      is_expected.to contain_neutron_config('keystone_authtoken/auth_protocol').with_value('http');
    end
  end

  describe "with custom keystone identity_uri" do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end
    before do
      params.merge!({
        :identity_uri => 'https://foo.bar:1234/',
      })
    end
    it 'configures identity_uri' do
      is_expected.to contain_neutron_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:1234/");
      # since only auth_uri is set the deprecated auth parameters should
      # still get set in case they are still in use
      is_expected.to contain_neutron_config('keystone_authtoken/auth_host').with_value('localhost');
      is_expected.to contain_neutron_config('keystone_authtoken/auth_port').with_value('35357');
      is_expected.to contain_neutron_config('keystone_authtoken/auth_protocol').with_value('http');
    end
  end

  describe "with custom keystone identity_uri and auth_uri" do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end
    before do
      params.merge!({
        :identity_uri => 'https://foo.bar:35357/',
        :auth_uri => 'https://foo.bar:5000/v2.0/',
      })
    end
    it 'configures identity_uri and auth_uri but deprecates old auth settings' do
      is_expected.to contain_neutron_config('keystone_authtoken/identity_uri').with_value("https://foo.bar:35357/");
      is_expected.to contain_neutron_config('keystone_authtoken/auth_uri').with_value("https://foo.bar:5000/v2.0/");
      is_expected.to contain_neutron_config('keystone_authtoken/auth_admin_prefix').with(:ensure => 'absent')
      is_expected.to contain_neutron_config('keystone_authtoken/auth_port').with(:ensure => 'absent')
      is_expected.to contain_neutron_config('keystone_authtoken/auth_protocol').with(:ensure => 'absent')
      is_expected.to contain_neutron_config('keystone_authtoken/auth_host').with(:ensure => 'absent')
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge(
        { :osfamily => 'Debian',
          :processorcount => '2' })
    end

    let :platform_params do
      { :server_package => 'neutron-server',
        :server_service => 'neutron-server' }
    end

    it_configures 'a neutron server'
    it_configures 'a neutron server with broken authentication'
    it_configures 'a neutron server with auth_admin_prefix set'
    it_configures 'a neutron server with some incorrect auth_admin_prefix set'
    it_configures 'a neutron server with database_connection specified'
    it_configures 'a neutron server without database synchronization'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge(
        { :osfamily => 'RedHat',
          :processorcount => '2' })
    end

    let :platform_params do
      { :server_service => 'neutron-server' }
    end

    it_configures 'a neutron server'
    it_configures 'a neutron server with broken authentication'
    it_configures 'a neutron server with auth_admin_prefix set'
    it_configures 'a neutron server with some incorrect auth_admin_prefix set'
    it_configures 'a neutron server with database_connection specified'
    it_configures 'a neutron server without database synchronization'
  end
end
