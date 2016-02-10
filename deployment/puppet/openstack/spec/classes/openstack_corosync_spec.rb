require 'spec_helper'

describe 'openstack::corosync' do

  let(:default_params) { {
    :bind_address             => '127.0.0.1',
    :multicast_address        => '239.1.1.2',
    :secauth                  => false,
    :stonith                  => false,
    :quorum_policy            => 'ignore',
    :expected_quorum_votes    => '2',
    :corosync_nodes           => ["UNSET"],
    :corosync_version         => '1',
    :packages                 => ['corosync', 'pacemaker'],
  } }

  let(:params) { {} }

  shared_examples_for 'corosync configuration' do
    let :p do
      default_params.merge(params)
    end

    it 'contains openstack::corosync' do
      should contain_class('openstack::corosync')
    end

    context 'with default params' do
      it 'configures with the default params' do
        should contain_class('corosync').with(
          :enable_secauth        => p[:secauth],
          :bind_address          => p[:bind_address],
          :multicast_address     => p[:multicast_address],
          :corosync_nodes        => p[:corosync_nodes],
          :corosync_version      => p[:corosync_version],
          :packages              => p[:packages],
          :debug                 => false,
        ).that_comes_before('Anchor[corosync-done]')
        should contain_file("limitsconf").that_comes_before(
          'Service[corosync]')
        should contain_corosync__service('pacemaker').with(
          :version => '0'
        ).that_notifies('Service[corosync]')
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian',
        :operatingsystem => 'Debian',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'corosync configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'corosync configuration'
  end

end
