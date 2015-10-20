require 'spec_helper'

describe 'tweaks::apache_wrappers' do

  let(:default_params) { {
  } }

  shared_examples_for 'tweaks::apache_wrappers configuration' do
    let :params do
      default_params
    end


    context 'with valid params' do
      let :params do
        default_params.merge({})
      end

      it 'configures with the default params' do
        should contain_class('tweaks::apache_wrappers')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'tweaks::apache_wrappers configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'tweaks::apache_wrappers configuration'
  end

end

