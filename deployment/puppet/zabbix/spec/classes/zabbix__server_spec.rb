require 'spec_helper'

describe 'zabbix::server' do
  context 'on gentoo' do
    let(:facts) {
      {
        :operatingsystem => 'Gentoo',
        :osfamily => 'gentoo',
      }
    }
    it {
      should contain_class('zabbix::server::gentoo')
      should contain_service('zabbix-server').with({
        :ensure => 'running',
        :enable => 'true',
      })
      should contain_file('/etc/zabbix/zabbix_server.conf')
    }
  end
  context 'it should have params' do
    let(:params) {
      {
        :ensure      => 'present',
        :conf_file   => 'undef',
        :template    => 'undef',
        :node_id     => 'undef',
        :db_server   => 'undef',
        :db_database => 'undef',
        :db_user     => 'undef',
        :db_password => 'undef',
        :export      => 'undef',
        :hostname    => 'undef',
      }
    }
  end
  context 'it should use hiera' do
    let(:hiera_data) { 
      { :server_enable => 'present' }
    }
    it {
      should contain_service('zabbix-server').with({
        :ensure => 'running'
      })
    }
  end
  context 'with export present', :broken => true do
    # testing exported resources seems generally broken
    # i would like to test this side for proper exporting
    # and then test it on the other side again like above
    let(:facts) {
      {
        :operatingsystem => 'Gentoo',
        'fqdn' => 'server_host'
      }
    }
    let(:params) {
      {
      'export' => 'present',
      }
    }
    it {
      should contain_zabbix__agent__server('server_host').with({
        :ensure   => 'present',
        :hostname => 'server_host'
      })
    }
  end
  context 'should always require an agent' do
    let(:facts) {
      {
        :operatingsystem => 'Gentoo'
      }
    }
    let(:params) {
      {
        :ensure => 'present'
      }
    }
    it {
      should contain_class('zabbix::agent')
    }
  end
  context 'should install activerecord' do

    let(:facts) {
      {
        :operatingsystem => 'Gentoo'
      }
    }
    let(:params) {
      {
        :ensure => 'present'
      }
    }
    it {
      should contain_package('activerecord').with({
        :ensure => 'present'
      })
    }
  end
end
