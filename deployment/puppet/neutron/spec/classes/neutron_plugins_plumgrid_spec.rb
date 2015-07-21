require 'spec_helper'

describe 'neutron::plugins::plumgrid' do

  let :pre_condition do
    "class { 'neutron::server': auth_password => 'password' }
     class { 'neutron': rabbit_password => 'passw0rd' }"
  end

  let :default_params do
  {
    :director_server      => '127.0.0.1',
    :director_server_port => '443',
    :servertimeout        => '99',
    :connection           => 'http://127.0.0.1:35357/v2.0',
    :controller_priv_host => '127.0.0.1',
    :auth_protocol        => 'http',
    :nova_metadata_ip     => '127.0.0.1',
    :nova_metadata_port   => '8775',
  }
  end

  let :default_facts do
    { :operatingsystem           => 'default',
      :operatingsystemrelease    => 'default'
    }
  end

  shared_examples_for 'neutron plumgrid plugin' do

    let :params do
      {}
    end

    before do
      params.merge!(default_params)
    end

    it 'installs plumgrid plugin package' do
      is_expected.to contain_package('neutron-plugin-plumgrid').with(
        :ensure => 'present'
      )
    end

    it 'installs plumgrid plumlib package' do
      is_expected.to contain_package('neutron-plumlib-plumgrid').with(
        :ensure => 'present'
      )
    end

    it 'should perform default configuration of plumgrid plugin' do
      is_expected.to contain_neutron_plugin_plumgrid('PLUMgridDirector/director_server').with_value(params[:director_server])
      is_expected.to contain_neutron_plugin_plumgrid('PLUMgridDirector/director_server_port').with_value(params[:director_server_port])
      is_expected.to contain_neutron_plugin_plumgrid('PLUMgridDirector/username').with_value(params[:username])
      is_expected.to contain_neutron_plugin_plumgrid('PLUMgridDirector/password').with_value(params[:password])
      is_expected.to contain_neutron_plugin_plumgrid('PLUMgridDirector/servertimeout').with_value(params[:servertimeout])
      is_expected.to contain_neutron_plugin_plumgrid('database/connection').with_value(params[:connection])
    end

    it 'should perform default configuration of plumgrid plumlib' do
      is_expected.to contain_neutron_plumlib_plumgrid('keystone_authtoken/admin_user').with_value('admin')
      is_expected.to contain_neutron_plumlib_plumgrid('keystone_authtoken/admin_password').with_value(params[:admin_password])
      is_expected.to contain_neutron_plumlib_plumgrid('keystone_authtoken/admin_tenant_name').with_value('admin')
      auth_uri = params[:auth_protocol] + "://" + params[:controller_priv_host] + ":" + "35357/v2.0";
      is_expected.to contain_neutron_plumlib_plumgrid('keystone_authtoken/auth_uri').with_value(auth_uri)
      is_expected.to contain_neutron_plumlib_plumgrid('PLUMgridMetadata/enable_pg_metadata').with_value('True')
      is_expected.to contain_neutron_plumlib_plumgrid('PLUMgridMetadata/metadata_mode').with_value('local')
      is_expected.to contain_neutron_plumlib_plumgrid('PLUMgridMetadata/nova_metadata_ip').with_value(params[:nova_metadata_ip])
      is_expected.to contain_neutron_plumlib_plumgrid('PLUMgridMetadata/nova_metadata_port').with_value(params[:nova_metadata_port])
      is_expected.to contain_neutron_plumlib_plumgrid('PLUMgridMetadata/metadata_proxy_shared_secret').with_value(params[:metadata_proxy_shared_secret])
    end

  end

  context 'on Debian platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'Debian'})
    end

    it 'configures /etc/default/neutron-server' do
      is_expected.to contain_file_line('/etc/default/neutron-server:NEUTRON_PLUGIN_CONFIG').with(
        :path    => '/etc/default/neutron-server',
        :match   => '^NEUTRON_PLUGIN_CONFIG=(.*)$',
        :line    => 'NEUTRON_PLUGIN_CONFIG=/etc/neutron/plugins/plumgrid/plumgrid.ini',
        :require => ['Package[neutron-server]', 'Package[neutron-plugin-plumgrid]'],
        :notify  => 'Service[neutron-server]'
      )
    end

    it_configures 'neutron plumgrid plugin'
  end

  context 'on RedHat platforms' do
    let :facts do
      default_facts.merge({ :osfamily => 'RedHat'})
    end

    it 'should create plugin symbolic link' do
      is_expected.to contain_file('/etc/neutron/plugin.ini').with(
        :ensure  => 'link',
        :target  => '/etc/neutron/plugins/plumgrid/plumgrid.ini',
        :require => 'Package[neutron-plugin-plumgrid]')
    end

    it_configures 'neutron plumgrid plugin'
  end

end
