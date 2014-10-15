require 'spec_helper'

describe 'openstack_extras::repo::rdo' do

  describe 'Fedora and folsom' do
    let :params do
      { :release => 'folsom' }
    end
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'Fedora',
        :operatingsystemrelease => '18',
      }
    end

    it 'should fail if invalid release is passed' do
      expect { subject }.to raise_error(Puppet::Error, /is not a supported RDO release/)
    end
  end

  describe 'RHEL and folsom' do
    let :params do
      { :release => 'folsom' }
    end
    let :facts do
      {
        :osfamily               => 'RedHat',
        :operatingsystem        => 'CentOS',
        :operatingsystemrelease => '6.4',
      }
    end

    it 'should fail if invalid release is passed' do
      expect { subject }.to raise_error(Puppet::Error, /is not a supported RDO release/)
    end
  end
end
