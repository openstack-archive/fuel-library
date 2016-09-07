require 'spec_helper'

describe 'vmware::compute_vmware', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      context 'with custom ca file' do
        let(:params) do
          {
            :availability_zone_name => 'vcenter',
            :vc_cluster             => 'Cluster1',
            :vc_host                => '172.16.0.254',
            :vc_user                => 'administrator@vsphere.local',
            :vc_password            => 'Qwer!1234',
            :service_name           => 'srv_cluster1',
            :current_node           => 'node-2',
            :target_node            => 'node-2',
            :vlan_interface         => 'vmnic0',
            :vc_insecure            => false,
            :vc_ca_file             => {
              'content' => 'RSA',
              'name'    => 'vcenter-ca.pem' },
            :datastore_regex        => '.*',
          }
        end

        let(:title) { '0' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__compute_vmware('0') }

        it { is_expected.to contain_class('nova::params') }

        it { is_expected.to contain_file('/etc/nova/vmware-ca.pem').with(
          :ensure  => 'file',
          :content => 'RSA',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
        ) }

        it do
          parameters = {
            :ensure  => 'present',
            :path    => '/etc/nova/nova-compute.conf',
            :mode    => '0600',
            :owner   => 'nova',
            :group   => 'nova',
          }

          is_expected.to contain_file('nova_compute_conf').with(parameters).that_notifies('Service[nova-compute]')
        end

        it { is_expected.to contain_package('nova-compute').with(
          :ensure => 'installed',
          :name   => 'nova-compute',
        ).that_comes_before('File[nova_compute_conf]') }

        it { is_expected.to contain_package('python-oslo.vmware').with(
          :ensure => 'installed',
        ).that_comes_before('Package[nova-compute]') }

        it { is_expected.to contain_service('nova-compute').with(
          :ensure => 'stopped',
          :name   => 'nova-compute',
          :enable => false,
        ) }
      end

      context 'without custom ca file' do
        let(:params) do
          {
            :availability_zone_name => 'vcenter',
            :vc_cluster             => 'Cluster2',
            :vc_host                => '172.16.0.254',
            :vc_user                => 'administrator@vsphere.local',
            :vc_password            => 'Qwer!1234',
            :service_name           => 'srv_cluster2',
            :current_node           => 'node-3',
            :target_node            => 'node-3',
            :vlan_interface         => '',
            :vc_insecure            => true,
            :vc_ca_file             => '',
            :datastore_regex        => '.*',
          }
        end

        let(:title) { '1' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__compute_vmware('1') }

        it { is_expected.to contain_class('nova::params') }

        it do
          parameters = {
            :ensure  => 'present',
            :path    => '/etc/nova/nova-compute.conf',
            :mode    => '0600',
            :owner   => 'nova',
            :group   => 'nova',
          }
          is_expected.to contain_file('nova_compute_conf').with(parameters).that_notifies('Service[nova-compute]')
        end

        it { is_expected.to contain_package('nova-compute').with(
          :ensure => 'installed',
          :name   => 'nova-compute',
        ).that_comes_before('File[nova_compute_conf]') }

        it { is_expected.to contain_package('python-oslo.vmware').with(
          :ensure => 'installed',
        ).that_comes_before('Package[nova-compute]') }

        it { is_expected.to contain_service('nova-compute').with(
          :ensure => 'stopped',
          :name   => 'nova-compute',
          :enable => false,
        ) }
      end

    end
  end
end
