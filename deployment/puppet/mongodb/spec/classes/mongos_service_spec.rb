require 'spec_helper'

describe 'mongodb::mongos::service', :type => :class do

  context 'on Debian' do
    let :facts do
      {
        :osfamily        => 'Debian',
        :operatingsystem => 'Debian',
      }
    end

    let :pre_condition do          
      "class { 'mongodb::mongos':
       }"
    end 

    describe 'include init script' do
      it { should contain_file('/etc/init.d/mongos') }
    end

    describe 'configure the mongos service' do
      it { should contain_service('mongos') }
    end
  end

  context 'on RedHat' do
    let :facts do
      {
        :osfamily        => 'RedHat',
        :operatingsystem => 'RedHat',
      }
    end

    let :pre_condition do
      "class { 'mongodb::mongos':
       }"
    end

    describe 'include mongos sysconfig file' do
      it { should contain_file('/etc/sysconfig/mongos') }
    end

    describe 'include init script' do
      it { should contain_file('/etc/init.d/mongos') }
    end

    describe 'configure the mongos service' do
      it { should contain_service('mongos') }
    end
  end


end
