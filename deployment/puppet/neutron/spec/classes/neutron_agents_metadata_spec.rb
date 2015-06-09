require 'spec_helper'

describe 'neutron::agents::metadata' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    { :package_ensure   => 'present',
      :debug            => false,
      :enabled          => true,
      :auth_url         => 'http://localhost:35357/v2.0',
      :auth_insecure    => false,
      :auth_region      => 'RegionOne',
      :auth_tenant      => 'services',
      :auth_user        => 'neutron',
      :auth_password    => 'password',
      :metadata_ip      => '127.0.0.1',
      :metadata_port    => '8775',
      :metadata_backlog => '4096',
      :shared_secret    => 'metadata-secret'
    }
  end

  shared_examples_for 'neutron metadata agent' do

    it { should contain_class('neutron::params') }

    it 'configures neutron metadata agent service' do
      should contain_service('neutron-metadata').with(
        :name    => platform_params[:metadata_agent_service],
        :enable  => params[:enabled],
        :ensure => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        should contain_service('neutron-metadata').without_ensure
      end
    end

    it 'configures metadata_agent.ini' do
      should contain_neutron_metadata_agent_config('DEFAULT/debug').with(:value => params[:debug])
      should contain_neutron_metadata_agent_config('DEFAULT/auth_url').with(:value => params[:auth_url])
      should contain_neutron_metadata_agent_config('DEFAULT/auth_insecure').with(:value => params[:auth_insecure])
      should contain_neutron_metadata_agent_config('DEFAULT/auth_ca_cert').with_ensure('absent')
      should contain_neutron_metadata_agent_config('DEFAULT/auth_region').with(:value => params[:auth_region])
      should contain_neutron_metadata_agent_config('DEFAULT/admin_tenant_name').with(:value => params[:auth_tenant])
      should contain_neutron_metadata_agent_config('DEFAULT/admin_user').with(:value => params[:auth_user])
      should contain_neutron_metadata_agent_config('DEFAULT/admin_password').with(:value => params[:auth_password])
      should contain_neutron_metadata_agent_config('DEFAULT/admin_password').with_secret( true )
      should contain_neutron_metadata_agent_config('DEFAULT/nova_metadata_ip').with(:value => params[:metadata_ip])
      should contain_neutron_metadata_agent_config('DEFAULT/nova_metadata_port').with(:value => params[:metadata_port])
      should contain_neutron_metadata_agent_config('DEFAULT/metadata_workers').with(:value => facts[:processorcount])
      should contain_neutron_metadata_agent_config('DEFAULT/metadata_backlog').with(:value => params[:metadata_backlog])
      should contain_neutron_metadata_agent_config('DEFAULT/metadata_proxy_shared_secret').with(:value => params[:shared_secret])
      should contain_neutron_metadata_agent_config('DEFAULT/cache_url').with(:value => 'memory://?default_ttl=5')
    end
  end

  shared_examples_for 'neutron metadata agent with auth_insecure and auth_ca_cert set' do
    let :params do
      { :auth_ca_cert  => '/some/cert',
        :auth_insecure => true,
        :auth_password => 'blah',
        :shared_secret => '42'
      }
    end

    it 'configures certificate' do
      should contain_neutron_metadata_agent_config('DEFAULT/auth_ca_cert').with_value('/some/cert')
      should contain_neutron_metadata_agent_config('DEFAULT/auth_insecure').with_value('true')
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :processorcount => '2' }
    end

    let :platform_params do
      { :metadata_agent_package => 'neutron-metadata-agent',
        :metadata_agent_service => 'neutron-metadata-agent' }
    end

    it 'installs neutron metadata agent package' do
      should contain_package('neutron-metadata').with(
        :ensure => params[:package_ensure],
        :name   => platform_params[:metadata_agent_package]
      )
    end

    it_configures 'neutron metadata agent'
    it_configures 'neutron metadata agent with auth_insecure and auth_ca_cert set'

  end

  context 'on Red Hat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :processorcount => '2' }
    end

    let :platform_params do
      { :metadata_agent_service => 'neutron-metadata-agent' }
    end

    it_configures 'neutron metadata agent'
    it_configures 'neutron metadata agent with auth_insecure and auth_ca_cert set'

  end

end
