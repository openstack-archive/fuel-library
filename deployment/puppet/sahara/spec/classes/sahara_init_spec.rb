#
# Unit tests for sahara::init
#
require 'spec_helper'

describe 'sahara' do

  let :params do
    {
      :keystone_password => 'secrete'
    }
  end

  shared_examples_for 'sahara' do
    it { is_expected.to contain_class('sahara::params') }
    it { is_expected.to contain_class('sahara::policy') }
    it { is_expected.to contain_class('mysql::bindings::python') }
    it { is_expected.to contain_exec('sahara-dbmanage') }
  end

  shared_examples_for 'sahara logging' do
    context 'with syslog disabled' do
      it { is_expected.to contain_sahara_config('DEFAULT/use_syslog').with_value(false) }
    end

    context 'with syslog enabled' do
      let :params do
        { :use_syslog   => 'true' }
      end

      it { is_expected.to contain_sahara_config('DEFAULT/use_syslog').with_value(true) }
      it { is_expected.to contain_sahara_config('DEFAULT/syslog_log_facility').with_value('LOG_USER') }
    end

    context 'with syslog enabled and custom settings' do
      let :params do
        {
          :use_syslog   => 'true',
          :log_facility => 'LOG_LOCAL0'
        }
      end

      it { is_expected.to contain_sahara_config('DEFAULT/use_syslog').with_value(true) }
      it { is_expected.to contain_sahara_config('DEFAULT/syslog_log_facility').with_value('LOG_LOCAL0') }
    end

    context 'with log_dir disabled' do
      let :params do
        { :log_dir => false }
      end
      it { is_expected.to contain_sahara_config('DEFAULT/log_dir').with_ensure('absent') }
    end

  end

  context 'on Debian platforms' do
    let :facts do
      {
        :osfamily => 'Debian',
        :operatingsystem => 'Debian'
      }
    end

    it_configures 'sahara'
    it_configures 'sahara logging'

    it_behaves_like 'generic sahara service', {
      :name         => 'sahara',
      :package_name => 'sahara',
      :service_name => 'sahara' }
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    it_configures 'sahara'
    it_configures 'sahara logging'

    it_behaves_like 'generic sahara service', {
      :name         => 'sahara',
      :package_name => 'openstack-sahara',
      :service_name => 'openstack-sahara-all' }

  end
end
