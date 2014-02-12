require 'spec_helper'

describe 'zabbix' do
  context "with params" do
    let(:params) {
      {
        :ensure   => 'undef',
        :agent    => 'undef',
        :server   => 'undef',
        :frontend => 'undef',
        :api      => 'undef',
        :export   => 'undef',
      }
    }
  end
  context "normal gentoo call" do
    let :facts do 
      {
        :operatingsystem => 'Gentoo',
        :zabbixvserion => '2.0.3'
      }
    end
    it {
      should contain_class('zabbix::gentoo').with({:ensure => 'present'})
      should contain_class('zabbix::agent').with({:ensure => 'present'})
      should contain_class('zabbix::server').with({:ensure => 'absent'})
      should contain_class('zabbix::frontend').with({:ensure => 'absent'})
    }
  end
  context "server gentoo call" do
    let :facts do 
      {
        :operatingsystem => 'Gentoo',
        :zabbixvserion => '2.0.3'

      }
    end
    let :params do
      {
        :server => 'present'
      }
    end
    it {
      should contain_class('zabbix::gentoo').with({:ensure => 'present'})
      should contain_class('zabbix::agent').with({:ensure => 'present'})
      should contain_class('zabbix::server').with({:ensure => 'present'})
      should contain_class('zabbix::frontend').with({:ensure => 'absent'})
    }
  end
  context "frontend gentoo call" do
    let :facts do 
      {
        :operatingsystem => 'Gentoo',
        :zabbixvserion => '2.0.3'

      }
    end
    let :params do
      {
        :frontend => 'present'
      }
    end
    it {
      should contain_class('zabbix::gentoo').with({:ensure => 'present'})
      should contain_class('zabbix::agent').with({:ensure => 'present'})
      should contain_class('zabbix::server').with({:ensure => 'absent'})
      should contain_class('zabbix::frontend').with({:ensure => 'present'})
    }
  end
  context "calls with export" do
    let :facts do
      {
        :operatingsystem => 'Gentoo'
      }
    end
    let :params do
      {
        :ensure => 'present',
        :export => 'present'
      }
    end
    it {
      should contain_class('zabbix::server').with({:export => 'present'})
    }
  end
end
