require 'spec_helper'

describe 'neutron::agents::lbaas' do

  let :pre_condition do
    "class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :params do
    {}
  end

  let :default_params do
    { :package_ensure   => 'present',
      :enabled          => true,
      :debug            => false,
      :interface_driver => 'neutron.agent.linux.interface.OVSInterfaceDriver',
      :device_driver    => 'neutron_lbaas.services.loadbalancer.drivers.haproxy.namespace_driver.HaproxyNSDriver',
      :use_namespaces   => true,
      :manage_haproxy_package  => true
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end


  shared_examples_for 'neutron lbaas agent' do
    let :p do
      default_params.merge(params)
    end

    it { is_expected.to contain_class('neutron::params') }

    it_configures 'haproxy lbaas_driver'
    it_configures 'haproxy lbaas_driver without package'

    it 'configures lbaas_agent.ini' do
      is_expected.to contain_neutron_lbaas_agent_config('DEFAULT/debug').with_value(p[:debug]);
      is_expected.to contain_neutron_lbaas_agent_config('DEFAULT/interface_driver').with_value(p[:interface_driver]);
      is_expected.to contain_neutron_lbaas_agent_config('DEFAULT/device_driver').with_value(p[:device_driver]);
      is_expected.to contain_neutron_lbaas_agent_config('DEFAULT/use_namespaces').with_value(p[:use_namespaces]);
      is_expected.to contain_neutron_lbaas_agent_config('haproxy/user_group').with_value(platform_params[:nobody_user_group]);
    end

    it 'installs neutron lbaas agent package' do
      is_expected.to contain_package('neutron-lbaas-agent').with(
        :name   => platform_params[:lbaas_agent_package],
        :ensure => p[:package_ensure],
        :tag    => 'openstack'
      )
      is_expected.to contain_package('neutron').with_before(/Package\[neutron-lbaas-agent\]/)
      is_expected.to contain_package('neutron-lbaas-agent').with_before(/Neutron_lbaas_agent_config\[.+\]/)
      is_expected.to contain_package('neutron-lbaas-agent').with_before(/Neutron_config\[.+\]/)
    end

    it 'configures neutron lbaas agent service' do
      is_expected.to contain_service('neutron-lbaas-service').with(
        :name    => platform_params[:lbaas_agent_service],
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
        is_expected.to contain_service('neutron-lbaas-service').without_ensure
      end
    end
  end

  shared_examples_for 'haproxy lbaas_driver' do
    it 'installs haproxy packages' do
      if platform_params.has_key?(:lbaas_agent_package)
        is_expected.to contain_package(platform_params[:haproxy_package]).with_before(['Package[neutron-lbaas-agent]'])
      end
      is_expected.to contain_package(platform_params[:haproxy_package]).with(
        :ensure => 'present'
      )
    end
  end

  shared_examples_for 'haproxy lbaas_driver without package' do
    let :pre_condition do
      "package { 'haproxy':
         ensure => 'present'
       }
      class { 'neutron': rabbit_password => 'passw0rd' }"
    end
    before do
      params.merge!(:manage_haproxy_package => false)
    end
    it 'installs haproxy package via haproxy module' do
      is_expected.to contain_package(platform_params[:haproxy_package]).with(
        :ensure => 'present'
      )
    end
  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge(
        { :osfamily => 'Debian',
          :concat_basedir => '/dne'
        }
      )
    end

    let :platform_params do
      { :haproxy_package     =>  'haproxy',
        :lbaas_agent_package => 'neutron-lbaas-agent',
        :nobody_user_group   => 'nogroup',
        :lbaas_agent_service => 'neutron-lbaas-agent' }
    end

    it_configures 'neutron lbaas agent'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge(
        { :osfamily => 'RedHat',
          :concat_basedir => '/dne'
        }
      )
    end

    let :platform_params do
      { :haproxy_package     => 'haproxy',
        :lbaas_agent_package => 'openstack-neutron-lbaas',
        :nobody_user_group   => 'nobody',
        :lbaas_agent_service => 'neutron-lbaas-agent' }
    end

    it_configures 'neutron lbaas agent'
  end
end
