require 'spec_helper'

describe 'zabbix::agent::param' do
  context "normal call" do
    let(:title) { 'foo.bar.baz' }
    
    let(:facts) { 
      {
        :operatingsystem => 'Gentoo'
      }
    }
    it {
      should contain_file('/etc/zabbix/zabbix_agentd.d/10_foo.bar.baz.conf').with({
        :ensure => 'present'
      })
    }
  end
  
  context "call with key" do
    let(:title) { 'my witty title' }
    
    let(:params) { 
      {
        :key => 'blergh.key'
      }
    }
    it {
      should contain_file('/etc/zabbix/zabbix_agentd.d/10_blergh.key.conf').with({
        :ensure => 'present'
      })
    }
  end
end