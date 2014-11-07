require 'spec_helper'

describe 'openstack_extras::repo::uca' do

  describe 'Ubuntu with defaults' do

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
        :lsbdistcodename        => 'precise',
        :lsbdistid              => 'ubuntu',
      }
    end
    it do
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-updates/icehouse'
      )
    end
  end

  describe 'Ubuntu and grizzly' do
    let :params do
      { :release => 'grizzly', :repo => 'proposed' }
    end

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
        :lsbdistcodename        => 'precise',
        :lsbdistid              => 'ubuntu',
      }
    end

    it do
      should contain_apt__source('ubuntu-cloud-archive').with(
        :release => 'precise-proposed/grizzly'
      )
    end
  end

  describe 'Ubuntu and bexar' do
    let :params do
      { :release => 'bexar',
        :repo    => 'proposed' }
    end

    let :facts do
      {
        :osfamily               => 'Debian',
        :operatingsystem        => 'Ubuntu',
        :operatingsystemrelease => '12.04',
        :lsbdistdescription     => 'Ubuntu 12.04.1 LTS',
        :lsbdistcodename        => 'precise',
        :lsbdistid              => 'ubuntu',
      }
    end

    it 'should fail if invalid release is passed' do
      expect { subject }.to raise_error(Puppet::Error, /is not a supported UCA release/)
    end
  end
end
