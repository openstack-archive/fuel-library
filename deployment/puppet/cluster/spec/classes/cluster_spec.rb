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

  on_supported_os(supported_os: supported_os).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      let :packages do
        if facts[:osfamily] == 'Debian'
          [ 'crmsh', 'pcs' ]
        else
          ['crmsh']
        end
      end

      it_configures 'cluster configuration'
    end
  end

end

