require 'spec_helper'

describe 'vmware::controller' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

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
            :vlan_interface    => '',
            :use_quantum       => true,
            :vncproxy_protocol => 'https',
            :vncproxy_host     => '172.16.0.4',
            :vncproxy_port     => '',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('nova::params') }

        it { is_expected.to contain_package('nova-compute').with(
          :ensure => 'present',
          :name   => 'nova-compute',
        ).that_comes_before('Service[nova-compute]') }

        it { is_expected.to contain_service('nova-compute').with(
          :ensure    => 'stopped',
          :name      => 'nova-compute',
        ) }

        it { is_expected.to contain_class('vmware::network').with(
          :use_quantum => params[:use_quantum],
        ) }

        it { is_expected.to contain_nova_config('DEFAULT/enabled_apis') \
          .with_value('ec2,osapi_compute,metadata') }

        it { is_expected.to contain_nova_config('vnc/novncproxy_base_url') \
          .with_value("#{params[:vncproxy_protocol]}://#{params[:vncproxy_host]}:#{params[:vncproxy_port]}/vnc_auto.html") }

        it { is_expected.to contain_package('cirros-testvmware').with(
          :ensure => 'present',
        ) }

        it { is_expected.to contain_package('python-suds').with(
          :ensure => 'present',
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
            :vlan_interface    => '',
            :use_quantum       => true,
            :vncproxy_protocol => 'https',
            :vncproxy_host     => '172.16.0.4',
            :vncproxy_port     => '',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('nova::params') }

        it { is_expected.to contain_package('nova-compute').with(
          :ensure => 'present',
          :name   => 'nova-compute',
        ).that_comes_before('Service[nova-compute]') }

        it { is_expected.to contain_service('nova-compute').with(
          :ensure    => 'stopped',
          :name      => 'nova-compute',
        ) }

        it { is_expected.to contain_class('vmware::network').with(
          :use_quantum => params[:use_quantum],
        ) }

        it { is_expected.to contain_nova_config('DEFAULT/enabled_apis') \
          .with_value('ec2,osapi_compute,metadata') }

        it { is_expected.to contain_nova_config('vnc/novncproxy_base_url') \
          .with_value("#{params[:vncproxy_protocol]}://#{params[:vncproxy_host]}:#{params[:vncproxy_port]}/vnc_auto.html") }

        it { is_expected.to contain_package('cirros-testvmware').with(
          :ensure => 'present',
        ) }

        it { is_expected.to contain_package('python-suds').with(
          :ensure => 'present',
        ) }
      end

    end
  end
end
