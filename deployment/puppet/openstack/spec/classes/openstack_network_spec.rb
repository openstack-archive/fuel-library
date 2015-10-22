require 'spec_helper'

describe 'openstack::network' do

  let(:default_params) { {
  } }

  let(:params) { {
    :auth_uri          => 'http://192.168.1.2:5000/v2.0/',
    :shared_secret     => 'very_secret',
    :private_interface => 'eth0',
    :public_interface  => 'eth1',
    :fixed_range       => '192.168.1.254/25',
    :neutron_server    => true,
    :neutron_db_uri    => 'sqlite:////var/lib/neutron/ovs.sqlite',
    :network_provider  => 'neutron'
  } }

  let :facts do
    { :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  shared_examples_for 'network configuration' do
    let :p do
      default_params.merge(params)
    end


    context 'with a default config' do
      it 'contains openstack::network' do
        should contain_class('openstack::network')
      end
      # LP#1509007 auth_uri should not be needed if identity_uri provided
      it 'contains neutron::server' do
        should contain_class('neutron::server').with(
          :auth_uri => 'http://192.168.1.2:5000/v2.0/',
        )
      end
    end
  end

  context 'on Debian platforms' do
    before do
      facts.merge!(
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :operatingsystemrelease => '8',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      })
    end

    it_configures 'network configuration'
  end

  context 'on RedHat platforms' do
    before do
      facts.merge!(
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '6.6',
        :hostname => 'hostname.example.com',
        :physicalprocessorcount => 2,
        :memorysize_mb => 1024,
        :openstack_version => {'nova' => 'present' },
      })
    end

    it_configures 'network configuration'
  end

end

