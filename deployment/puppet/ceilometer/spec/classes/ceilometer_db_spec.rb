require 'spec_helper'

describe 'ceilometer::db' do

  # debian has "python-pymongo"
  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :params do
      { :database_connection => 'mongodb://localhost:1234/ceilometer',
        :sync_db             => true }
    end

    it { should contain_class('ceilometer::params') }

    it 'installs python-mongodb package' do
      should contain_package('ceilometer-backend-package').with(
        :ensure => 'present',
        :name => 'python-pymongo')
      should contain_ceilometer_config('database/connection').with_value('mongodb://localhost:1234/ceilometer')
    end

    it 'runs ceilometer-dbsync' do
      should contain_exec('ceilometer-dbsync').with(
        :command     => 'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf',
        :path        => '/usr/bin',
        :refreshonly => 'true',
        :user        => 'ceilometer',
        :logoutput   => 'on_failure'
      )
    end
  end

  # Fedora > 18 has python-pymongo too
  context 'on Redhat platforms' do
    let :facts do
      { :osfamily => 'Redhat',
        :operatingsystem => 'Fedora',
        :operatingsystemrelease => 18
      }
    end

    let :params do
      { :database_connection => 'mongodb://localhost:1234/ceilometer',
        :sync_db             => false }
    end

    it { should contain_class('ceilometer::params') }

    it 'installs pymongo package' do
      should contain_package('ceilometer-backend-package').with(
        :ensure => 'present',
        :name => 'python-pymongo')
      should contain_ceilometer_config('database/connection').with_value('mongodb://localhost:1234/ceilometer')
    end

    it 'runs ceilometer-dbsync' do
      should contain_exec('ceilometer-dbsync').with(
        :command     => '/bin/true',
        :path        => '/usr/bin',
        :refreshonly => 'true',
        :user        => 'ceilometer',
        :logoutput   => 'on_failure'
      )
    end
  end

  # RHEL has python-pymongo too
  context 'on Redhat platforms' do
    let :facts do
      { :osfamily => 'Redhat',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => 6.4
      }
    end

    let :params do
      { :database_connection => 'mongodb://localhost:1234/ceilometer',
        :sync_db             => true }
    end

    it { should contain_class('ceilometer::params') }

    it 'installs pymongo package' do
      should contain_package('ceilometer-backend-package').with(
        :ensure => 'present',
        :name => 'python-pymongo')
    end

    it 'runs ceilometer-dbsync' do
      should contain_exec('ceilometer-dbsync').with(
        :command     => 'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf',
        :path        => '/usr/bin',
        :refreshonly => 'true',
        :user        => 'ceilometer',
        :logoutput   => 'on_failure'
      )
    end
  end

  # RHEL has python-sqlite2
  context 'on Redhat platforms' do
    let :facts do
      { :osfamily => 'Redhat',
        :operatingsystem => 'CentOS',
        :operatingsystemrelease => 6.4
      }
    end

    let :params do
      { :database_connection => 'sqlite:///var/lib/ceilometer.db',
        :sync_db             => false }
    end

    it { should contain_class('ceilometer::params') }

    it 'installs pymongo package' do
      should contain_package('ceilometer-backend-package').with(
        :ensure => 'present',
        :name => 'python-sqlite2')
      should contain_ceilometer_config('database/connection').with_value('sqlite:///var/lib/ceilometer.db')
    end

    it 'runs ceilometer-dbsync' do
      should contain_exec('ceilometer-dbsync').with(
        :command     => '/bin/true',
        :path        => '/usr/bin',
        :refreshonly => 'true',
        :user        => 'ceilometer',
        :logoutput   => 'on_failure'
      )
    end
  end

  # debian has "python-pysqlite2"
  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :params do
      { :database_connection => 'sqlite:///var/lib/ceilometer.db',
        :sync_db             => true }
    end

    it { should contain_class('ceilometer::params') }

    it 'installs python-mongodb package' do
      should contain_package('ceilometer-backend-package').with(
        :ensure => 'present',
        :name => 'python-pysqlite2')
    end

    it 'runs ceilometer-dbsync' do
      should contain_exec('ceilometer-dbsync').with(
        :command     => 'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf',
        :path        => '/usr/bin',
        :refreshonly => 'true',
        :user        => 'ceilometer',
        :logoutput   => 'on_failure'
      )
    end
  end

end

