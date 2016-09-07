require 'spec_helper'

describe 'vmware::ceilometer::ha', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts.merge(common_facts) }

      context 'with custom ca file' do
        let(:params) do
          {
            :availability_zone_name => 'vcenter',
            :service_name           => 'srv_cluster1',
            :target_node            => 'controllers',
            :default_log_levels     => 'amqp=DEBUG,amqplib=DEBUG,boto=WARN',
            :vc_cluster             => 'Cluster1',
            :vc_host                => '172.16.0.254',
            :vc_password            => 'Qwer!1234',
            :vc_user                => 'administrator@vsphere.local',
            :vc_insecure            => false,
            :vc_ca_file             => {
              'content' => 'RSA',
              'name'    => 'vcenter-ca.pem' },
          }
        end

        let(:title) { '0' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__ceilometer__ha('0') }

        it { is_expected.to contain_file('/etc/ceilometer/ceilometer-compute.d').with(
          :ensure => 'directory',
          :owner  => 'ceilometer',
          :group  => 'ceilometer',
          :mode   => '0750',
        ).that_comes_before('File[/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster1.conf]') }

        it { is_expected.to contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster1-ca.pem').with(
          :ensure  => 'file',
          :content => 'RSA',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
        ) }

        it do
          content = <<-eof
[DEFAULT]

# Name of this node, which must be valid in an AMQP key. Can be an opaque
# identifier. For ZeroMQ only, must be a valid host name, FQDN, or IP address.
#host=localhost
host=vcenter-srv_cluster1

# Inspector to use for inspecting the hypervisor layer. Known inspectors are
# libvirt, hyperv, vmware, xenapi and powervm.
#hypervisor_inspector=libvirt
hypervisor_inspector=vmware

# List of package logging levels in logger=LEVEL pairs. This option is ignored
# if log_config_append is set.
#default_log_levels=amqp=WARN, amqplib=WARN, boto=WARN, qpid=WARN,
#sqlalchemy=WARN, suds=INFO, oslo.messaging=INFO, iso8601=WARN,
#requests.packages.urllib3.connectionpool=WARN, urllib3.connectionpool=WARN,
#websocket=WARN, requests.packages.urllib3.util.retry=WARN,
#urllib3.util.retry=WARN, keystonemiddleware=WARN, routes.middleware=WARN,
#stevedore=WARN, taskflow=WARN, keystoneauth=WARN, oslo.cache=INFO,
#dogpile.core.dogpile=INFO
default_log_levels=amqp=DEBUG,amqplib=DEBUG,boto=WARN

# Name of log file to send logging output to. If no default is set, logging will
# go to stderr as defined by use_stderr. This option is ignored if
# log_config_append is set.
#log_file=None
log_file=ceilometer-agent-compute-vmware-vcenter-srv_cluster1.log


[vmware]

# Number of times a VMware vSphere API may be retried.
#api_retry_count=10
api_retry_count=5

# CA bundle file to use in verifying the vCenter server certificate.
#ca_file=None
ca_file=/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster1-ca.pem

# IP address of the VMware vSphere host.
#host_ip=
host_ip=172.16.0.254

# Password of VMware vSphere.
#host_password=
host_password=Qwer!1234

# Port of the VMware vSphere host.
#host_port=443

# Username of VMware vSphere.
#host_username=
host_username=administrator@vsphere.local

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "ca_file" is set.
#insecure=False
insecure=false

# Sleep time in seconds for polling an ongoing async task.
#task_poll_interval=0.5
task_poll_interval=5.0

# Optional vim service WSDL location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds.
#wsdl_location=None
          eof

          parameters = {
            :ensure  => 'present',
            :mode    => '0600',
            :owner   => 'ceilometer',
            :group   => 'ceilometer',
            :content => content,
          }
          is_expected.to contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster1.conf') \
            .with(parameters).that_comes_before('Pcmk_resource[p_ceilometer_agent_compute_vmware_vcenter_srv_cluster1]')
        end

        it { is_expected.to contain_pcmk_resource('p_ceilometer_agent_compute_vmware_vcenter_srv_cluster1').with(
          :primitive_class    => 'ocf',
          :primitive_provider => 'fuel',
          :primitive_type     => 'ceilometer-agent-compute',
          :metadata           => {
            'target-role'         => 'stopped',
            'resource-stickiness' => '1' },
          :parameters         => {
            'amqp_server_port'      => '5673',
            'config'                => '/etc/ceilometer/ceilometer.conf',
            'pid'                   => '/var/run/ceilometer/ceilometer-agent-compute-vcenter_srv_cluster1.pid',

            'user'                  => 'ceilometer',
            'additional_parameters' => '--config-file=/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster1.conf', },
          :operations         => {
            'monitor'  => {
              'timeout'  => '20',
              'interval' => '30', },
            'start'    => {
              'timeout' => '360', },
            'stop'     => {
              'timeout' => '360', } },
        ).that_comes_before('Service[p_ceilometer_agent_compute_vmware_vcenter_srv_cluster1]') }

        it { is_expected.to contain_service('p_ceilometer_agent_compute_vmware_vcenter_srv_cluster1').with(
          :ensure => 'running',
          :enable => true,
        ) }
      end

      context 'without custom ca file' do
        let(:params) do
          {
            :availability_zone_name => 'vcenter',
            :service_name           => 'srv_cluster2',
            :target_node            => 'controllers',
            :default_log_levels     => 'amqp=DEBUG,amqplib=DEBUG,boto=WARN',
            :vc_cluster             => 'Cluster2',
            :vc_host                => '172.16.0.254',
            :vc_password            => 'Qwer!1234',
            :vc_user                => 'administrator@vsphere.local',
            :vc_insecure            => true,
            :vc_ca_file             => '',
          }
        end

        let(:title) { '1' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__ceilometer__ha('1') }

        it { is_expected.to contain_file('/etc/ceilometer/ceilometer-compute.d').with(
          :ensure => 'directory',
          :owner  => 'ceilometer',
          :group  => 'ceilometer',
          :mode   => '0750',
        ).that_comes_before('File[/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster2.conf]') }

        it do
          content = <<-eof
[DEFAULT]

# Name of this node, which must be valid in an AMQP key. Can be an opaque
# identifier. For ZeroMQ only, must be a valid host name, FQDN, or IP address.
#host=localhost
host=vcenter-srv_cluster2

# Inspector to use for inspecting the hypervisor layer. Known inspectors are
# libvirt, hyperv, vmware, xenapi and powervm.
#hypervisor_inspector=libvirt
hypervisor_inspector=vmware

# List of package logging levels in logger=LEVEL pairs. This option is ignored
# if log_config_append is set.
#default_log_levels=amqp=WARN, amqplib=WARN, boto=WARN, qpid=WARN,
#sqlalchemy=WARN, suds=INFO, oslo.messaging=INFO, iso8601=WARN,
#requests.packages.urllib3.connectionpool=WARN, urllib3.connectionpool=WARN,
#websocket=WARN, requests.packages.urllib3.util.retry=WARN,
#urllib3.util.retry=WARN, keystonemiddleware=WARN, routes.middleware=WARN,
#stevedore=WARN, taskflow=WARN, keystoneauth=WARN, oslo.cache=INFO,
#dogpile.core.dogpile=INFO
default_log_levels=amqp=DEBUG,amqplib=DEBUG,boto=WARN

# Name of log file to send logging output to. If no default is set, logging will
# go to stderr as defined by use_stderr. This option is ignored if
# log_config_append is set.
#log_file=None
log_file=ceilometer-agent-compute-vmware-vcenter-srv_cluster2.log


[vmware]

# Number of times a VMware vSphere API may be retried.
#api_retry_count=10
api_retry_count=5

# CA bundle file to use in verifying the vCenter server certificate.
#ca_file=None

# IP address of the VMware vSphere host.
#host_ip=
host_ip=172.16.0.254

# Password of VMware vSphere.
#host_password=
host_password=Qwer!1234

# Port of the VMware vSphere host.
#host_port=443

# Username of VMware vSphere.
#host_username=
host_username=administrator@vsphere.local

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "ca_file" is set.
#insecure=False
insecure=true

# Sleep time in seconds for polling an ongoing async task.
#task_poll_interval=0.5
task_poll_interval=5.0

# Optional vim service WSDL location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds.
#wsdl_location=None
          eof

          parameters = {
            :ensure  => 'present',
            :mode    => '0600',
            :owner   => 'ceilometer',
            :group   => 'ceilometer',
            :content => content,
          }
          is_expected.to contain_file('/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster2.conf') \
            .with(parameters).that_comes_before('Pcmk_resource[p_ceilometer_agent_compute_vmware_vcenter_srv_cluster2]')
        end

        it { is_expected.to contain_pcmk_resource('p_ceilometer_agent_compute_vmware_vcenter_srv_cluster2').with(
          :primitive_class    => 'ocf',
          :primitive_provider => 'fuel',
          :primitive_type     => 'ceilometer-agent-compute',
          :metadata           => {
            'target-role'         => 'stopped',
            'resource-stickiness' => '1' },
          :parameters         => {
            'amqp_server_port'      => '5673',
            'config'                => '/etc/ceilometer/ceilometer.conf',
            'pid'                   => '/var/run/ceilometer/ceilometer-agent-compute-vcenter_srv_cluster2.pid',

            'user'                  => 'ceilometer',
            'additional_parameters' => '--config-file=/etc/ceilometer/ceilometer-compute.d/vmware-vcenter_srv_cluster2.conf', },
          :operations         => {
            'monitor'  => {
              'timeout'  => '20',
              'interval' => '30', },
            'start'    => {
              'timeout' => '360', },
            'stop'     => {
              'timeout' => '360', } },
        ).that_comes_before('Service[p_ceilometer_agent_compute_vmware_vcenter_srv_cluster2]') }

        it { is_expected.to contain_service('p_ceilometer_agent_compute_vmware_vcenter_srv_cluster2').with(
          :ensure => 'running',
          :enable => true,
        ) }
      end

    end
  end
end
