require 'spec_helper'

describe 'nova::scheduler' do

  let :pre_condition do
    'include nova'
  end

  let :params do
    { :enabled => true }
  end

  shared_examples 'nova-scheduler' do


    it { is_expected.to contain_package('nova-scheduler').with(
      :name   => platform_params[:scheduler_package_name],
      :ensure => 'present'
    ) }

    it { is_expected.to contain_service('nova-scheduler').with(
      :name      => platform_params[:scheduler_service_name],
      :hasstatus => 'true',
      :ensure    => 'running'
    )}

    context 'with manage_service as false' do
      let :params do
        { :enabled        => true,
          :manage_service => false
        }
      end
      it { is_expected.to contain_service('nova-scheduler').without_ensure }
    end

    context 'with package version' do
      let :params do
        { :ensure_package => '2012.1-2' }
      end

      it { is_expected.to contain_package('nova-scheduler').with(
        :ensure => params[:ensure_package]
      )}
    end

    context 'with default database parameters' do
      let :pre_condition do
        "include nova"
      end

      it { is_expected.to_not contain_nova_config('database/connection') }
      it { is_expected.to_not contain_nova_config('database/slave_connection') }
      it { is_expected.to_not contain_nova_config('database/idle_timeout').with_value('3600') }
    end

    context 'with overridden database parameters' do
      let :pre_condition do
        "class { 'nova':
           database_connection   => 'mysql://user:pass@db/db',
           slave_connection      => 'mysql://user:pass@slave/db',
           database_idle_timeout => '30',
         }
        "
      end

      it { is_expected.to contain_nova_config('database/connection').with_value('mysql://user:pass@db/db').with_secret(true) }
      it { is_expected.to contain_nova_config('database/slave_connection').with_value('mysql://user:pass@slave/db').with_secret(true) }
      it { is_expected.to contain_nova_config('database/idle_timeout').with_value('30') }
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :scheduler_package_name => 'nova-scheduler',
        :scheduler_service_name => 'nova-scheduler' }
    end

    it_configures 'nova-scheduler'
  end

  context 'on Redhat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :scheduler_package_name => 'openstack-nova-scheduler',
        :scheduler_service_name => 'openstack-nova-scheduler' }
    end

    it_configures 'nova-scheduler'
  end

end
