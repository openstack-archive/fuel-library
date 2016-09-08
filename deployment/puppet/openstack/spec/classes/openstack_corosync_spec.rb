require 'spec_helper'

describe 'openstack::corosync' do

  let(:default_params) { {
    :bind_address             => '127.0.0.1',
    :multicast_address        => nil,
    :secauth                  => false,
    :stonith                  => false,
    :quorum_policy            => 'ignore',
    :quorum_members           => ['localhost'],
    :quorum_members_ids       => nil,
    :unicast_addresses        => ['127.0.0.1'],
    :packages                 => nil,
    :cluster_recheck_interval => '190s'
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
          :set_votequorum        => true,
          :quorum_members        => p[:quorum_members],
          :quorum_members_ids    => p[:quorum_members_ids],
          :unicast_addresses     => p[:unicast_addresses],
          :debug                 => false,
          :log_stderr            => false,
          :log_function_name     => true,
        ).that_comes_before('Anchor[corosync-done]')
        should contain_file("limitsconf").that_comes_before(
          'Service[corosync]')
        should contain_corosync__service('pacemaker').with(
          :version => '1'
        ).that_notifies('Service[corosync]')
        {
          'no-quorum-policy'         => p[:quorum_policy],
          'stonith-enabled'          => p[:stonith],
          'start-failure-is-fatal'   => false,
          'symmetric-cluster'        => false,
          'cluster-recheck-interval' => p[:cluster_recheck_interval],
        }.each do |prop, val|
          should contain_pcmk_property(prop).with(
            :ensure   => 'present',
            :value    => val,
          ).that_comes_before('Anchor[corosync-done]')
        end
      end
    end

    context 'with custom packages' do
       before do
         params.merge!({
           :packages => ['baz', 'qux'],
         })
      end

      it 'configures packages' do
        ['baz', 'qux'].each do |package|
          should contain_package(package).that_comes_before(
             'Anchor[corosync-done]')
        end
      end
    end
  end

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      it_configures 'corosync configuration'
    end
  end

end
