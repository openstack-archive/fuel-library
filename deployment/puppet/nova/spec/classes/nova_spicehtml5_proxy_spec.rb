require 'spec_helper'

describe 'nova::spicehtml5proxy' do

  let :pre_condition do
    'include nova'
  end

  let :params do
    { :enabled => true }
  end

  shared_examples 'nova-spicehtml5proxy' do

    it 'configures nova.conf' do
      should contain_nova_config('DEFAULT/spicehtml5proxy_host').with(:value => '0.0.0.0')
      should contain_nova_config('DEFAULT/spicehtml5proxy_port').with(:value => '6082')
    end

    it { should contain_package('nova-spicehtml5proxy').with(
      :name   => platform_params[:spicehtml5proxy_package_name],
      :ensure => 'present'
    ) }

    it { should contain_service('nova-spicehtml5proxy').with(
      :name      => platform_params[:spicehtml5proxy_service_name],
      :hasstatus => 'true',
      :ensure    => 'running'
    )}

    context 'with package version' do
      let :params do
        { :ensure_package => '2012.1-2' }
      end

      it { should contain_package('nova-spicehtml5proxy').with(
        :ensure => params[:ensure_package]
      )}
    end
  end

  context 'on Ubuntu system' do
    let :facts do
      { :osfamily        => 'Debian',
        :operatingsystem => 'Ubuntu' }
    end

    let :platform_params do
      { :spicehtml5proxy_package_name => 'nova-spiceproxy',
        :spicehtml5proxy_service_name => 'nova-spicehtml5proxy' }
    end

    it_configures 'nova-spicehtml5proxy'
  end

  context 'on Debian system' do
    let :facts do
      { :osfamily        => 'Debian',
        :operatingsystem => 'Debian' }
    end

    let :platform_params do
      { :spicehtml5proxy_package_name => 'nova-consoleproxy',
        :spicehtml5proxy_service_name => 'nova-spicehtml5proxy' }
    end

    it_configures 'nova-spicehtml5proxy'
  end

  context 'on Redhat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :spicehtml5proxy_package_name => 'openstack-nova-console',
        :spicehtml5proxy_service_name => 'openstack-nova-spicehtml5proxy' }
    end

    it_configures 'nova-spicehtml5proxy'
  end

end
