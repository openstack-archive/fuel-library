require 'spec_helper'

describe 'cluster::dns_ocf' do

  let(:default_params) { {
  } }

  shared_examples_for 'dns_ocf configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      it_raises 'a Puppet::Error', /primary_controller/
    end

    context 'with primary_controller = true' do
      let :params do
        default_params.merge!({
          :primary_controller => true,
        })
      end

      it 'configures with the params params' do
        should contain_class('cluster::dns_ocf')
        should contain_cs_resource('p_dns').with_before(['Cs_rsc_colocation[dns-with-vrouter-ns]'])
        should contain_cs_rsc_colocation('dns-with-vrouter-ns').with(
          :ensure => 'present',
          :score  => 'INFINITY',
          :primitives => [ 'clone_p_dns', 'clone_p_vrouter' ])
        should contain_service('p_dns').with(
          :name       => 'p_dns',
          :enable     => true,
          :ensure     => 'running',
          :hasstatus  => true,
          :hasrestart => true,
          :provider   => 'pacemaker')
      end
    end

    context 'with primary_controller = false' do
      let :params do
        default_params.merge!({
          :primary_controller => false,
        })
      end

      it 'configures with the params params' do
        should_not contain_cs_resource('p_dns')
        should_not contain_cs_rsc_colocation('dns-with-vrouter-ns')
        should contain_service('p_dns').with(
          :name       => 'p_dns',
          :enable     => true,
          :ensure     => 'running',
          :hasstatus  => true,
          :hasrestart => true,
          :provider   => 'pacemaker')

      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'dns_ocf configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'dns_ocf configuration'
  end

end

