require 'spec_helper'

describe 'cluster' do

  let(:default_params) { {
    :internal_address         => '127.0.0.1',
    :cluster_recheck_interval => '190s',
  } }

  shared_examples_for 'cluster configuration' do
    let :params do
      default_params
    end

    context 'with valid params' do
      let :params do
        default_params.merge!({
          :corosync_nodes => { 'node-1' => { 'ip' => '127.0.0.1', 'id' => '1' } }
        })
      end

      it 'configures with the params params' do
        should contain_class('cluster')
        should contain_class('openstack::corosync').with(
          :bind_address             => '127.0.0.1',
          :corosync_nodes           => params[:corosync_nodes],
          :corosync_version         => 2,
          :packages                 => ['corosync', 'pacemaker', 'crmsh', 'pcs'],
          :cluster_recheck_interval => params[:cluster_recheck_interval])
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
        :hostname => 'hostname.example.com', }
    end

    it_configures 'cluster configuration'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
        :hostname => 'hostname.example.com', }
    end

    it_configures 'cluster configuration'
  end

end

