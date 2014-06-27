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
    { :package_ensure          => 'present',
      :enabled                 => true,
      :auth_type               => 'keystone',
      :auth_host               => 'localhost',
      :auth_port               => '35357',
      :auth_tenant             => 'services',
      :auth_user               => 'neutron',
      :database_connection     => 'sqlite:////var/lib/neutron/ovs.sqlite',
      :database_max_retries    => '10',
      :database_idle_timeout   => '3600',
      :database_retry_interval => '10',
      :sync_db                 => false,
      :api_workers             => '0',
      :agent_down_time         => '75',
      :router_scheduler_driver => 'neutron.scheduler.l3_agent_scheduler.ChanceScheduler',
      :mysql_module            => '0.9'}
  end

  shared_examples_for 'a neutron server' do
    let :p do
      default_params.merge(params)
    end

    it 'should perform default database configuration of' do
      should contain_neutron_config('database/connection').with_value(p[:database_connection])
      should contain_neutron_config('database/max_retries').with_value(p[:database_max_retries])
      should contain_neutron_config('database/idle_timeout').with_value(p[:database_idle_timeout])
      should contain_neutron_config('database/retry_interval').with_value(p[:database_retry_interval])
    end

    it { should contain_class('neutron::params') }

    it 'configures authentication middleware' do
      should contain_neutron_api_config('filter:authtoken/auth_host').with_value(p[:auth_host]);
      should contain_neutron_api_config('filter:authtoken/auth_port').with_value(p[:auth_port]);
      should contain_neutron_api_config('filter:authtoken/admin_tenant_name').with_value(p[:auth_tenant]);
      should contain_neutron_api_config('filter:authtoken/admin_user').with_value(p[:auth_user]);
      should contain_neutron_api_config('filter:authtoken/admin_password').with_value(p[:auth_password]);
      should contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(:ensure => 'absent')
      should contain_neutron_api_config('filter:authtoken/auth_uri').with_value("http://localhost:5000/");
    end

    it 'installs neutron server package' do
      if platform_params.has_key?(:server_package)
        should contain_package('neutron-server').with(
          :name   => platform_params[:server_package],
          :ensure => p[:package_ensure]
        )
        should contain_package('neutron-server').with_before(/Neutron_api_config\[.+\]/)
        should contain_package('neutron-server').with_before(/Neutron_config\[.+\]/)
        should contain_package('neutron-server').with_before(/Service\[neutron-server\]/)
      else
        should contain_package('neutron').with_before(/Neutron_api_config\[.+\]/)
      end
    end

    it 'configures neutron server service' do
      should contain_service('neutron-server').with(
        :name    => platform_params[:server_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
      should_not contain_exec('neutron-db-sync')
      should contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(
        :ensure => 'absent'
      )
      should contain_neutron_config('DEFAULT/api_workers').with_value('0')
      should contain_neutron_config('DEFAULT/agent_down_time').with_value('75')
      should contain_neutron_config('DEFAULT/router_scheduler_driver').with_value('neutron.scheduler.l3_agent_scheduler.ChanceScheduler')
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        should contain_service('neutron-server').without_ensure
      end
    end
  end

  shared_examples_for 'a neutron server with auth_admin_prefix set' do
    [ '/keystone', '/keystone/admin', '' ].each do |auth_admin_prefix|
      describe "with keystone_auth_admin_prefix containing incorrect value #{auth_admin_prefix}" do
        before do
          params.merge!({
            :auth_admin_prefix => auth_admin_prefix,
          })
        end
        it do
          should contain_neutron_api_config('filter:authtoken/auth_admin_prefix').with(
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
        it do
          expect {
            should contain_neutron_api_config('filter:authtoken/auth_admin_prefix')
          }.to raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/)
        end
      end
    end
  end

  shared_examples_for 'a neutron server with broken authentication' do
    before do
      params.delete(:auth_password)
    end
    it_raises 'a Puppet::Error', /auth_password must be set/
  end

  shared_examples_for 'a neutron server with removed log_dir parameter' do
    before { params.merge!({ :log_dir  => '/var/log/neutron' })}
    it_raises 'a Puppet::Error', /log_dir parameter is removed/
  end

  shared_examples_for 'a neutron server with removed log_file parameter' do
    before { params.merge!({ :log_file  => '/var/log/neutron/blah.log' })}
    it_raises 'a Puppet::Error', /log_file parameter is removed/
  end

  shared_examples_for 'a neutron server without database synchronization' do
    before do
      params.merge!(
        :sync_db => true
      )
    end
    it 'should exec neutron-db-sync' do
      should contain_exec('neutron-db-sync').with(
        :command     => 'neutron-db-manage --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini upgrade head',
        :path        => '/usr/bin',
        :before      => 'Service[neutron-server]',
        :require     => 'Neutron_config[database/connection]',
        :refreshonly => true
      )
    end
  end

  shared_examples_for 'a neutron server with deprecated parameters' do

    context 'first generation' do
      before do
        params.merge!({
          :sql_connection          => 'sqlite:////var/lib/neutron/ovs-deprecated_parameter.sqlite',
          :database_connection     => 'sqlite:////var/lib/neutron/ovs-IGNORED_parameter.sqlite',
          :sql_max_retries         => 20,
          :database_max_retries    => 90,
          :sql_idle_timeout        => 21,
          :database_idle_timeout   => 91,
          :sql_reconnect_interval  => 22,
          :database_retry_interval => 92,
        })
      end

      it 'configures database connection with deprecated parameters' do
        should contain_neutron_config('database/connection').with_value(params[:sql_connection])
        should contain_neutron_config('database/max_retries').with_value(params[:sql_max_retries])
        should contain_neutron_config('database/idle_timeout').with_value(params[:sql_idle_timeout])
        should contain_neutron_config('database/retry_interval').with_value(params[:sql_reconnect_interval])
      end
    end

    context 'second generation' do
      before do
        params.merge!({
          :connection              => 'sqlite:////var/lib/neutron/ovs-deprecated_parameter.sqlite',
          :database_connection     => 'sqlite:////var/lib/neutron/ovs-IGNORED_parameter.sqlite',
          :max_retries             => 20,
          :database_max_retries    => 90,
          :idle_timeout            => 21,
          :database_idle_timeout   => 91,
          :retry_interval          => 22,
          :database_retry_interval => 92,
        })
      end

      it 'configures database connection with deprecated parameters' do
        should contain_neutron_config('database/connection').with_value(params[:connection])
        should contain_neutron_config('database/max_retries').with_value(params[:max_retries])
        should contain_neutron_config('database/idle_timeout').with_value(params[:idle_timeout])
        should contain_neutron_config('database/retry_interval').with_value(params[:retry_interval])
      end
    end
  end

  shared_examples_for 'a neutron server with database_connection specified' do
    before do
      params.merge!(
        :database_connection => 'sqlite:////var/lib/neutron/ovs-TEST_parameter.sqlite'
      )
    end
    it 'configures database connection' do
      should contain_neutron_config('database/connection').with_value(params[:database_connection])
    end
  end

  describe "with custom keystone auth_uri" do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    before do
      params.merge!({
        :auth_uri => 'https://foo.bar:1234/',
      })
    end
    it 'configures auth_uri' do
      should contain_neutron_api_config('filter:authtoken/auth_uri').with_value("https://foo.bar:1234/");
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :server_package => 'neutron-server',
        :server_service => 'neutron-server' }
    end

    it_configures 'a neutron server'
    it_configures 'a neutron server with broken authentication'
    it_configures 'a neutron server with auth_admin_prefix set'
    it_configures 'a neutron server with some incorrect auth_admin_prefix set'
    it_configures 'a neutron server with deprecated parameters'
    it_configures 'a neutron server with database_connection specified'
    it_configures 'a neutron server without database synchronization'
    it_configures 'a neutron server with removed log_file parameter'
    it_configures 'a neutron server with removed log_dir parameter'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :server_service => 'neutron-server' }
    end

    it_configures 'a neutron server'
    it_configures 'a neutron server with broken authentication'
    it_configures 'a neutron server with auth_admin_prefix set'
    it_configures 'a neutron server with some incorrect auth_admin_prefix set'
    it_configures 'a neutron server with deprecated parameters'
    it_configures 'a neutron server with database_connection specified'
    it_configures 'a neutron server without database synchronization'
    it_configures 'a neutron server with removed log_file parameter'
    it_configures 'a neutron server with removed log_dir parameter'
  end
end
