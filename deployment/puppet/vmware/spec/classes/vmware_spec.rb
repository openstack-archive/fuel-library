require 'spec_helper'

describe 'vmware' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default parameters' do

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('vmware::controller').with(
          :vcenter_settings  => nil,
          :vcenter_user      => 'user',
          :vcenter_password  => 'password',
          :vcenter_host_ip   => '10.10.10.10',
          :vlan_interface    => nil,
          :use_quantum       => true,
          :vncproxy_protocol => 'http',
          :vncproxy_host     => nil,
          :vncproxy_port     => '6080',
        ) }
      end

      context 'with custom parameters' do

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
            :vlan_interface    => '',
            :use_quantum       => true,
            :vncproxy_protocol => 'https',
            :vncproxy_host     => '172.16.0.4',
            :nova_hash         => {
              'db_password' => 'JoF3Wti3kn2Hm2RaD12SVvbI',
              'enable_hugepages' => false, 'state_path' => '/var/lib/nova',
              'user_password' => 'tEHRJ4biwyk4Z1JOempJVnXp',
              'vncproxy_protocol' => 'http', 'nova_rate_limits' => {
                'POST' => '100000', 'POST_SERVERS' => '100000', 'PUT' => '1000',
                'GET' => '100000', 'DELETE' => '100000' },
              'nova_report_interval' => '60', 'nova_service_down_time' => '180',
              'num_networks' => nil, 'network_size' => nil, 'network_manager' => nil },
            :ceilometer        => true,
            :debug             => true,
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('vmware::controller').with(
          :vcenter_settings  => params[:vcenter_settings],
          :vcenter_user      => params[:vcenter_user],
          :vcenter_password  => params[:vcenter_password],
          :vcenter_host_ip   => params[:vcenter_host_ip],
          :vlan_interface    => params[:vlan_interface],
          :use_quantum       => params[:use_quantum],
          :vncproxy_protocol => params[:vncproxy_protocol],
          :vncproxy_host     => params[:vncproxy_host],
          :vncproxy_port     => '6080',
        ) }

        it { is_expected.to contain_class('vmware::ceilometer').with(
          :vcenter_settings => params[:vcenter_settings],
          :vcenter_user     => params[:vcenter_user],
          :vcenter_password => params[:vcenter_password],
          :vcenter_host_ip  => params[:vcenter_host_ip],
          :vcenter_cluster  => params[:vcenter_cluster],
          :debug            => params[:debug],
        ) }
      end

    end
  end
end
