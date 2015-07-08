require 'spec_helper'

describe 'neutron::agents::dhcp' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure         => 'present',
      :enabled                => true,
      :debug                  => false,
      :state_path             => '/var/lib/neutron',
      :resync_interval        => 30,
      :interface_driver       => 'neutron.agent.linux.interface.OVSInterfaceDriver',
      :dhcp_domain            => 'openstacklocal',
      :dhcp_driver            => 'neutron.agent.linux.dhcp.Dnsmasq',
      :root_helper            => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf',
      :use_namespaces         => true,
      :dnsmasq_config_file    => nil,
      :dhcp_delete_namespaces => false,
      :enable_isolated_metadata => false,
      :enable_metadata_network  => false }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'neutron dhcp agent' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('neutron::params') }

    it_configures 'dnsmasq dhcp_driver'

    it 'configures dhcp_agent.ini' do
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/debug').with_value(p[:debug]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/state_path').with_value(p[:state_path]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/resync_interval').with_value(p[:resync_interval]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/interface_driver').with_value(p[:interface_driver]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/dhcp_domain').with_value(p[:dhcp_domain]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/dhcp_driver').with_value(p[:dhcp_driver]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/root_helper').with_value(p[:root_helper]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/use_namespaces').with_value(p[:use_namespaces]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/dhcp_delete_namespaces').with_value(p[:dhcp_delete_namespaces]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_isolated_metadata').with_value(p[:enable_isolated_metadata]);
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_metadata_network').with_value(p[:enable_metadata_network]);
    end

    it 'installs neutron dhcp agent package' do
      if platform_params.has_key?(:dhcp_agent_package)
        is_expected.to contain_package('neutron-dhcp-agent').with(
          :name   => platform_params[:dhcp_agent_package],
          :ensure => p[:package_ensure],
          :tag    => 'openstack'
        )
        is_expected.to contain_package('neutron').with_before(/Package\[neutron-dhcp-agent\]/)
        is_expected.to contain_package('neutron-dhcp-agent').with_before(/Neutron_dhcp_agent_config\[.+\]/)
        is_expected.to contain_package('neutron-dhcp-agent').with_before(/Neutron_config\[.+\]/)
      else
        is_expected.to contain_package('neutron').with_before(/Neutron_dhcp_agent_config\[.+\]/)
      end
    end

    it 'configures neutron dhcp agent service' do
      is_expected.to contain_service('neutron-dhcp-service').with(
        :name    => platform_params[:dhcp_agent_service],
        :enable  => true,
        :ensure  => 'running',
        :require => 'Class[Neutron]'
      )
    end

    context 'with manage_service as false' do
      before :each do
        params.merge!(:manage_service => false)
      end
      it 'should not start/stop service' do
        is_expected.to contain_service('neutron-dhcp-service').without_ensure
      end
    end

    context 'when enabling isolated metadata only' do
      before :each do
        params.merge!(:enable_isolated_metadata => true, :enable_metadata_network => false)
      end
      it 'should enable isolated_metadata only' do
        is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_isolated_metadata').with_value('true');
        is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_metadata_network').with_value('false');
      end
    end

    context 'when enabling isolated metadata with metadata networks' do
      before :each do
        params.merge!(:enable_isolated_metadata => true, :enable_metadata_network => true)
      end
      it 'should enable both isolated_metadata and metadata_network' do
        is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_isolated_metadata').with_value('true');
        is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/enable_metadata_network').with_value('true');
      end
    end

    context 'when enabling metadata networks without enabling isolated metadata' do
      before :each do
        params.merge!(:enable_isolated_metadata => false, :enable_metadata_network => true)
      end

      it_raises 'a Puppet::Error', /enable_metadata_network to true requires enable_isolated_metadata also enabled./
    end
  end

  shared_examples_for 'neutron dhcp agent with dnsmasq_config_file specified' do
    before do
      params.merge!(
        :dnsmasq_config_file => '/foo'
      )
    end
    it 'configures dnsmasq_config_file' do
      is_expected.to contain_neutron_dhcp_agent_config('DEFAULT/dnsmasq_config_file').with_value(params[:dnsmasq_config_file])
    end
  end

  shared_examples_for 'dnsmasq dhcp_driver' do
    it 'installs dnsmasq packages' do
      if platform_params.has_key?(:dhcp_agent_package)
        is_expected.to contain_package(platform_params[:dnsmasq_base_package]).with_before(['Package[neutron-dhcp-agent]'])
        is_expected.to contain_package(platform_params[:dnsmasq_utils_package]).with_before(['Package[neutron-dhcp-agent]'])
      end
      is_expected.to contain_package(platform_params[:dnsmasq_base_package]).with(
        :ensure => 'present',
        :name   => platform_params[:dnsmasq_base_package]
      )
      is_expected.to contain_package(platform_params[:dnsmasq_utils_package]).with(
        :ensure => 'present',
        :name   => platform_params[:dnsmasq_utils_package]
      )
    end
  end


  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :platform_params do
      { :dnsmasq_base_package  => 'dnsmasq-base',
        :dnsmasq_utils_package => 'dnsmasq-utils',
        :dhcp_agent_package    => 'neutron-dhcp-agent',
        :dhcp_agent_service    => 'neutron-dhcp-agent' }
    end

    it_configures 'neutron dhcp agent'
    it_configures 'neutron dhcp agent with dnsmasq_config_file specified'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :platform_params do
      { :dnsmasq_base_package  => 'dnsmasq',
        :dnsmasq_utils_package => 'dnsmasq-utils',
        :dhcp_agent_service    => 'neutron-dhcp-agent' }
    end

    it_configures 'neutron dhcp agent'
    it_configures 'neutron dhcp agent with dnsmasq_config_file specified'
  end
end
