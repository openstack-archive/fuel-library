require 'spec_helper.rb'
require 'shared-examples'

describe 'percona', :type => :class do
  context 'Defaults on CentOS' do
    let(:facts) { Facts.centos_facts }
    it_behaves_like 'compile'
    it_behaves_like 'test-packages', true
    it_behaves_like 'test-packages', false
  end
  context 'Defaults on Ubuntu' do
    let(:facts) { Facts.ubuntu_facts }
    it_behaves_like 'compile'
    it {
      should contain_file('/usr/sbin/policy-rc.d')
      should contain_file('/etc/apt/apt.conf.d/99tmp')
      should contain_exec('rm-policy-rc.d')
      should contain_exec('rm-99tmp')
    }
    it_behaves_like 'test-packages', true
    it_behaves_like 'test-packages', false
  end
end
# vim: set ts=2 sw=2 et :
