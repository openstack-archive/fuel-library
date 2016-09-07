require 'spec_helper'

describe 'vmware::ceilometer' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      context 'with custom ca file' do

        let(:params) do
          {
            :vcenter_settings  => {
              'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*',
              'service_name' => 'srv_cluster1', 'target_node' => 'controllers',
              'vc_cluster' => 'Cluster1', 'vc_host' => '172.16.0.145',
              'vc_password' => 'vmware', 'vc_user' => 'root',
              'vc_insecure' => 'false', 'vc_ca_file' => {
                'content' => 'RSA', 'name' => 'vcenter-ca.pem'} },
            :vcenter_user      => 'user',
            :vcenter_password  => 'password',
            :vcenter_host_ip   => '10.10.10.10',
            :vcenter_cluster   => 'cluster',
            :debug             => true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('ceilometer::params') }

        it { is_expected.to contain_package('ceilometer-agent-compute').with(
          :ensure => 'present',
          :name   => 'ceilometer-agent-compute',
        ) }
      end

      context 'without custom ca file' do
        let(:params) do
          {
            :vcenter_settings  => {
              'availability_zone_name' => 'vcenter', 'datastore_regex' => '.*',
              'service_name' => 'srv_cluster1', 'target_node' => 'controllers',
              'vc_cluster' => 'Cluster1', 'vc_host' => '172.16.0.145',
              'vc_password' => 'vmware', 'vc_user' => 'root',
              'vc_insecure' => 'true', 'vc_ca_file' => '' },
              :vcenter_user      => 'user',
              :vcenter_password  => 'password',
              :vcenter_host_ip   => '10.10.10.10',
              :vcenter_cluster   => 'cluster',
              :debug             => true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('ceilometer::params') }

        it { is_expected.to contain_package('ceilometer-agent-compute').with(
          :ensure => 'present',
          :name   => 'ceilometer-agent-compute',
        ) }
      end

    end
  end
end
