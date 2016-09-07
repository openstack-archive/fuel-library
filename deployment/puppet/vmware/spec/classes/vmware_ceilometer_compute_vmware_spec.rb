require 'spec_helper'

describe 'vmware::ceilometer::compute_vmware' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      context 'with custom ca file' do

        let(:params) do
          {
            :debug                  => true,
            :availability_zone_name => 'vcenter',
            :vc_cluster             => 'Cluster1',
            :vc_host                => '172.16.0.254',
            :vc_user                => 'administrator@vsphere.local',
            :vc_password            => 'Qwer!1234',
            :vc_insecure            => false,
            :vc_ca_file             => {
              'content' => 'RSA',
              'name'    => 'vcenter-ca.pem' },
            :service_name           => 'vmcluster1',
            :identity_uri           => 'http://172.16.1.4:5000',
            :auth_user              => 'ceilometer',
            :auth_password          => 'GCqFEGzzDHvQSVYBJsX4qGhO',
            :tenant                 => 'services',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('vmware::ssl').with(
          :vc_insecure    => params[:vc_insecure],
          :vc_ca_file     => params[:vc_ca_file],
          :vc_ca_filepath => '/etc/ceilometer/vmware-ca.pem',
        ) }

        it { is_expected.to contain_ceilometer_config('DEFAULT/default_log_levels') \
          .with_value('amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=DEBUG') }

        it { is_expected.to contain_ceilometer_config('DEFAULT/hypervisor_inspector') \
          .with_value('vmware') }

        it { is_expected.to contain_ceilometer_config('DEFAULT/host') \
          .with_value("#{params[:availability_zone_name]}-#{params[:service_name]}") }

        it { is_expected.to contain_ceilometer_config('vmware/host_ip') \
          .with_value(params[:vc_host]) }

        it { is_expected.to contain_ceilometer_config('vmware/host_username') \
          .with_value(params[:vc_user]) }

        it { is_expected.to contain_ceilometer_config('vmware/host_password') \
          .with_value(params[:vc_password]) }

        it { is_expected.to contain_ceilometer_config('vmware/ca_file') \
          .with_value('/etc/ceilometer/vmware-ca.pem') }

        it { is_expected.to contain_ceilometer_config('vmware/insecure') \
          .with_value(params[:vc_insecure]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_user') \
          .with_value(params[:auth_user]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_password') \
          .with_value(params[:auth_password]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_tenant_name') \
          .with_value(params[:tenant]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/identity_uri') \
          .with_value(params[:identity_uri]) }

        it { is_expected.to contain_class('ceilometer::params') }

        it { is_expected.to contain_package('ceilometer-polling').with(
          :ensure => 'latest',
          :name   => 'ceilometer-polling',
        ) }

        it { is_expected.to contain_service('ceilometer-polling').with(
          :ensure    => 'running',
          :name      => 'ceilometer-polling',
        ) }
      end

      context 'without custom ca file' do
        let(:params) do
          {
            :debug                  => false,
            :availability_zone_name => 'vcenter',
            :vc_cluster             => 'Cluster1',
            :vc_host                => '172.16.0.254',
            :vc_user                => 'administrator@vsphere.local',
            :vc_password            => 'Qwer!1234',
            :vc_insecure            => true,
            :vc_ca_file             => '',
            :service_name           => 'vmcluster1',
            :identity_uri           => 'http://172.16.1.4:5000',
            :auth_user              => 'ceilometer',
            :auth_password          => 'GCqFEGzzDHvQSVYBJsX4qGhO',
            :tenant                 => 'services',
          }
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_class('vmware::ssl').with(
          :vc_insecure    => params[:vc_insecure],
          :vc_ca_file     => params[:vc_ca_file],
          :vc_ca_filepath => '/etc/ceilometer/vmware-ca.pem',
        ) }

        it { is_expected.to contain_ceilometer_config('DEFAULT/default_log_levels') \
          .with_value('amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=WARN') }

        it { is_expected.to contain_ceilometer_config('DEFAULT/hypervisor_inspector') \
          .with_value('vmware') }

        it { is_expected.to contain_ceilometer_config('DEFAULT/host') \
          .with_value("#{params[:availability_zone_name]}-#{params[:service_name]}") }

        it { is_expected.to contain_ceilometer_config('vmware/host_ip') \
          .with_value(params[:vc_host]) }

        it { is_expected.to contain_ceilometer_config('vmware/host_username') \
          .with_value(params[:vc_user]) }

        it { is_expected.to contain_ceilometer_config('vmware/host_password') \
          .with_value(params[:vc_password]) }

        it { is_expected.to contain_ceilometer_config('vmware/ca_file') \
          .with_value('<SERVICE DEFAULT>') }

        it { is_expected.to contain_ceilometer_config('vmware/insecure') \
          .with_value(params[:vc_insecure]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_user') \
          .with_value(params[:auth_user]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_password') \
          .with_value(params[:auth_password]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/admin_tenant_name') \
          .with_value(params[:tenant]) }

        it { is_expected.to contain_ceilometer_config('keystone_authtoken/identity_uri') \
          .with_value(params[:identity_uri]) }

        it { is_expected.to contain_class('ceilometer::params') }

        it { is_expected.to contain_package('ceilometer-polling').with(
          :ensure => 'latest',
          :name   => 'ceilometer-polling',
        ) }

        it { is_expected.to contain_service('ceilometer-polling').with(
          :ensure    => 'running',
          :name      => 'ceilometer-polling',
        ) }
      end

    end
  end
end
