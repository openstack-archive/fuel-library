require 'spec_helper'

describe 'neutron::plugins::opencontrail' do

  let :pre_condition do
    "class { 'neutron::server': auth_password => 'password' }
     class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_params do
    { :api_server_ip              => '10.0.0.1',
      :api_server_port            => '8082',
      :multi_tenancy              => 'true',
      :contrail_extensions        => ['ipam:ipam','policy:policy','route-table'],
      :keystone_auth_url          => 'http://keystone-server:5000/v2.0',
      :keystone_admin_user        => 'admin',
      :keystone_admin_tenant_name => 'admin',
      :keystone_admin_password    => 'admin',
      :keystone_admin_token       => 'token1'
    }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'neutron opencontrail plugin' do

    let :params do
      {}
    end

    before do
      params.merge!(default_params)
    end

    it 'should perform default configuration of' do
      is_expected.to contain_neutron_plugin_opencontrail('APISERVER/api_server_ip').with_value(params[:api_server_ip])
      is_expected.to contain_neutron_plugin_opencontrail('APISERVER/api_server_port').with_value(params[:api_server_port])
      is_expected.to contain_neutron_plugin_opencontrail('APISERVER/multi_tenancy').with_value(params[:multi_tenancy])
      is_expected.to contain_neutron_plugin_opencontrail('APISERVER/contrail_extensions').with_value(params[:contrail_extensions].join(','))
      is_expected.to contain_neutron_plugin_opencontrail('KEYSTONE/auth_url').with_value(params[:keystone_auth_url])
      is_expected.to contain_neutron_plugin_opencontrail('KEYSTONE/admin_user').with_value(params[:keystone_admin_user])
      is_expected.to contain_neutron_plugin_opencontrail('KEYSTONE/admin_tenant_name').with_value(params[:keystone_admin_tenant_name])
      is_expected.to contain_neutron_plugin_opencontrail('KEYSTONE/admin_password').with_value(params[:keystone_admin_password])
      is_expected.to contain_neutron_plugin_opencontrail('KEYSTONE/admin_token').with_value(params[:keystone_admin_token])
    end

  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian' })
    end

    let :params do
      { :contrail_extensions => ['ipam:ipam','policy:policy','route-table'] }
    end

    it 'configures /etc/default/neutron-server' do
      is_expected.to contain_file_line('/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG').with(
        :path    => '/etc/default/neutron-server',
        :match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
        :line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugins/opencontrail/ContrailPlugin.ini',
        :require => ['Package[neutron-server]', 'Package[neutron-plugin-contrail]'],
        :notify  => 'Service[neutron-server]'
      )
    end
    it_configures 'neutron opencontrail plugin'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat' })
    end

    let :params do
      { :contrail_extensions => ['ipam:ipam','policy:policy','route-table'] }
    end

    it 'should create plugin symbolic link' do
      is_expected.to contain_file('/etc/neutron/plugin.ini').with(
        :ensure  => 'link',
        :target  => '/etc/neutron/plugins/opencontrail/ContrailPlugin.ini',
        :require => 'Package[neutron-plugin-contrail]'
      )
    end
    it_configures 'neutron opencontrail plugin'
  end

end
