require 'spec_helper'

describe 'tweaks::ubuntu_service_override' do
  let(:title) { 'something' }

  let(:default_params) { {
    :service_name => title,
    :package_name => title
  } }

  shared_examples_for 'tweaks::ubuntu_service_override configuration' do
    let :params do
      default_params
    end


    context 'with valid params' do
      let :params do
        default_params.merge({})
      end

      it 'configures with the default params' do
        should contain_tweaks__ubuntu_service_override(title)
        if facts[:operatingsystem] == 'Ubuntu'
          should contain_file('create-policy-rc.d').with(
            :ensure  => 'present',
            :path    => '/usr/sbin/policy-rc.d',
            :content => "#!/bin/bash\nexit 101",
            :mode    => '0755',
            :owner   => 'root',
            :group   => 'root')
          should contain_exec('remove-policy-rc.d').with(
            :command => 'rm -f /usr/sbin/policy-rc.d',
            :onlyif  => 'test -f /usr/sbin/policy-rc.d')
        else
          should_not contain_file('create-policy-rc.d')
          should_not contain_exec('remove-policy-rc.d')
        end
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'tweaks::ubuntu_service_override configuration'
  end

  context 'on Ubuntu platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Ubuntu',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'tweaks::ubuntu_service_override configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'tweaks::ubuntu_service_override configuration'
  end

end

