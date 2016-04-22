require 'spec_helper'

describe 'cluster' do

  let(:default_params) { {
    :internal_address         => '127.0.0.1',
    :quorum_members           => ['localhost'],
    :unicast_addresses        => ['127.0.0.1'],
    :cluster_recheck_interval => '190s',
  } }

  shared_examples_for 'cluster configuration' do
    let :params do
      default_params
    end

    context 'with default params' do
      it 'configures corosync with pacemaker' do
        should contain_class('openstack::corosync').with(
          :bind_address             => default_params[:internal_address],
          :quorum_members           => default_params[:quorum_members],
          :unicast_addresses        => default_params[:unicast_addresses],
          :packages                 => packages,
          :cluster_recheck_interval => default_params[:cluster_recheck_interval])
        should contain_file('ocf-fuel-path').with(
          :ensure  => 'directory',
          :path    => '/usr/lib/ocf/resource.d/fuel',
          :recurse => true,
          :owner   => 'root',
          :group   => 'root')
      end
    end

  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :operatingsystemrelease => '8',
        :hostname => 'hostname.example.com', }
    end

    let(:packages) { [ 'crmsh', 'pcs' ] }
    it_configures 'cluster configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :operatingsystemrelease => '7.2',
        :hostname => 'hostname.example.com', }
    end

    let(:packages) { ['crmsh'] }
    it_configures 'cluster configuration'
  end

end

