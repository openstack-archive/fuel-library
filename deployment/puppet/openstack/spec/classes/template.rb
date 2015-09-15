require 'spec_helper'

describe 'openstack::thing' do

  let(:default_params) { {
    :debug => false,
  } }

  let(:params) { {} }

  shared_examples_for 'thing configuration' do
    let :p do
      default_params.merge(params)
    end

    it 'contains openstack::thing' do
      should contain_class('openstack::thing')
    end

    context 'with default params' do
      it 'configures with the default params' do
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'thing configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'thing configuration'
  end

end

