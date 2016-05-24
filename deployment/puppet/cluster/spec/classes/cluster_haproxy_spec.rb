require 'spec_helper'

describe 'cluster::haproxy' do
  shared_examples_for 'cluster::haproxy configuration' do
    context 'with default params' do
      it 'includes haproxy classes' do
        should contain_class('haproxy::base')
        should contain_class('cluster::haproxy::rsyslog')
        should contain_class('cluster::haproxy_ocf')
      end

      it 'installs haproxy package' do
        should contain_package('haproxy')
        should contain_tweaks__ubuntu_service_override('haproxy')
      end

      it 'manages haproxy service' do
        should contain_service('haproxy')
      end

      it 'enables ip_nonlocal_bind' do
        should contain_sysctl__value('net.ipv4.ip_nonlocal_bind').with_value('1')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com',
        :concat_basedir => '/tmp',
      }
    end

    it_configures 'cluster::haproxy configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemmajrelease => '7',
        :hostname => 'hostname.example.com',
        :concat_basedir => '/tmp'
      }
    end

    it_configures 'cluster::haproxy configuration'
  end

end
