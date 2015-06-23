require 'spec_helper'

describe 'cinder::scheduler' do

  describe 'on debian platforms' do

    let :facts do
      { :osfamily => 'Debian' }
    end

    describe 'with default parameters' do

      it { is_expected.to contain_class('cinder::params') }
      it { is_expected.to contain_cinder_config('DEFAULT/scheduler_driver').with_ensure('absent') }

      it { is_expected.to contain_package('cinder-scheduler').with(
        :name   => 'cinder-scheduler',
        :ensure => 'present',
        :before => ['Cinder_config[DEFAULT/scheduler_driver]','Service[cinder-scheduler]'],
        :tag    => 'openstack',
      ) }

      it { is_expected.to contain_service('cinder-scheduler').with(
        :name      => 'cinder-scheduler',
        :enable    => true,
        :ensure    => 'running',
        :require   => 'Package[cinder]',
        :hasstatus => true
      ) }
    end

    describe 'with parameters' do

      let :params do
        { :scheduler_driver => 'cinder.scheduler.filter_scheduler.FilterScheduler',
          :package_ensure   => 'present'
        }
      end

      it { is_expected.to contain_cinder_config('DEFAULT/scheduler_driver').with_value('cinder.scheduler.filter_scheduler.FilterScheduler') }
      it { is_expected.to contain_package('cinder-scheduler').with_ensure('present') }
    end

    describe 'with manage_service false' do
      let :params do
        { 'manage_service' => false
        }
      end
      it 'should not change the state of the service' do
        is_expected.to contain_service('cinder-scheduler').without_ensure
      end
    end
  end


  describe 'on rhel platforms' do

    let :facts do
      { :osfamily => 'RedHat' }
    end

    describe 'with default parameters' do

      it { is_expected.to contain_class('cinder::params') }

      it { is_expected.to contain_service('cinder-scheduler').with(
        :name    => 'openstack-cinder-scheduler',
        :enable  => true,
        :ensure  => 'running',
        :require => 'Package[cinder]'
      ) }
    end

    describe 'with parameters' do

      let :params do
        { :scheduler_driver => 'cinder.scheduler.filter_scheduler.FilterScheduler' }
      end

      it { is_expected.to contain_cinder_config('DEFAULT/scheduler_driver').with_value('cinder.scheduler.filter_scheduler.FilterScheduler') }
    end
  end
end
