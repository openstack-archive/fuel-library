require 'spec_helper'

describe 'vmware::compute::ha', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with custom ca file' do
        let(:params) do
          {
            :availability_zone_name => 'vcenter',
            :vc_cluster             => 'Cluster1',
            :vc_host                => '172.16.0.254',
            :vc_user                => 'administrator@vsphere.local',
            :vc_password            => 'Qwer!1234',
            :service_name           => 'srv_cluster1',
            :target_node            => 'controllers',
            :vc_insecure            => false,
            :vc_ca_file             => {
              'content' => 'RSA',
              'name'    => 'vcenter-ca.pem' },
            :datastore_regex        => '.*',
          }
        end

        let(:title) { '0' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__compute__ha('0') }

        it { is_expected.to contain_file('/etc/nova/nova-compute.d').with(
          :ensure => 'directory',
          :owner  => 'nova',
          :group  => 'nova',
          :mode   => '0750',
        ).that_comes_before('File[/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster1.conf]') }

        it { is_expected.to contain_file('/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster1-ca.pem').with(
          :ensure  => 'file',
          :content => 'RSA',
          :mode    => '0644',
          :owner   => 'root',
          :group   => 'root',
        ) }

        it do
          content = <<-eof
[DEFAULT]

# Driver to use for controlling virtualization.
# Options include: libvirt.LibvirtDriver, xenapi.XenAPIDriver, fake.FakeDriver,
# ironic.IronicDriver, vmwareapi.VMwareVCDriver, hyperv.HyperVDriver
#compute_driver=None
compute_driver=vmwareapi.VMwareVCDriver

# Name of log file to output to. If no default is set, logging will go to
# stdout. This option is ignored if log_config_append is set.
#log_file=None
log_file=nova-compute-vmware-vcenter-srv_cluster1.log

# Name of this node. This can be an opaque identifier. It is not necessarily a
# hostname, FQDN, or IP address. However, the node name must be valid within an
# AMQP key, and if using ZeroMQ, a valid hostname, FQDN, or IP address.
#host=localhost
host=vcenter-srv_cluster1

# Amount of memory in MB to reserve for the host.
#reserved_host_memory_mb=512
reserved_host_memory_mb = 0

# Force injection to take place on a config drive.
#force_config_drive = False
force_config_drive=False


[vmware]

# The number of times we retry on failures, e.g., socket error, etc.
#api_retry_count=10
api_retry_count=5

# Specify a CA bundle file to use in verifying the vCenter server certificate.
#ca_file=None
ca_file=/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster1-ca.pem

# The prefix for where cached images are stored. This is NOT the full path -
# just a folder prefix. This should only be used when a datastore cache should
# be shared between compute nodes. Note: this should only be used when the
# compute nodes have a shared file system.
#cache_prefix=None
cache_prefix=$host

# Name of a VMware Cluster ComputeResource.
#cluster_name=None
cluster_name=Cluster1

# Set this value if affected by an increased network latency causing repeated
# characters when typing in a remote console.
#console_delay_seconds=None

# Regex to match the name of a datastore.
#datastore_regex=None
datastore_regex=.*

# Hostname or IP address for connection to VMware vCenter host.
#host_ip=None
host_ip=172.16.0.254

# Password for connection to VMware vCenter host.
#host_password=None
host_password=Qwer!1234

# Port for connection to VMware vCenter host.
#host_port = 443

# Username for connection to VMware vCenter host.
#host_username=None
host_username=administrator@vsphere.local

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "ca_file" is set.
#insecure = False
insecure=false

# This option should be configured only when using the NSX-MH Neutron plugin.
# This is the name of the integration bridge on the ESXi. This should not be set
# for any other Neutron plugin. Hence the default value is not set.
#integration_bridge=None

# The maximum number of ObjectContent data objects that should be returned in a
# single result. A positive value will cause the operation to suspend the
# retrieval when the count of objects reaches the specified maximum. The server
# may still limit the count to something less than the configured value. Any
# remaining objects may be retrieved with additional requests.
#maximum_objects = 100
maximum_objects=100

# The PBM default policy. If pbm_wsdl_location is set and there is no defined
# storage policy for the specific request then this policy will be used.
#pbm_default_policy=None

# The PBM status.
#pbm_enabled=False

# PBM service WSDL file location URL.
# e.g. file:///opt/SDK/spbm/wsdl/pbmService.wsdl Not setting this will disable
# storage policy based placement of instances.
#pbm_wsdl_location=None

# Identifies a proxy service that provides network access to the
# serial_port_service_uri. This option is ignored if serial_port_service_uri is
# not specified.
#serial_port_proxy_uri=None

# Identifies the remote system that serial port traffic will be sent to. If this
# is not set, no serial ports will be added to the created VMs.
#serial_port_service_uri=None

# The interval used for polling of remote tasks.
#task_poll_interval=0.5
task_poll_interval=5.0

# Whether to use linked clone
#use_linked_clone=True
use_linked_clone=true

# Optional VIM Service WSDL Location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds.
#wsdl_location=None

# Physical ethernet adapter name for vlan networking
#vlan_interface=vmnic0

# VNC starting port.
#vnc_port=5900

# Total number of VNC ports
#vnc_port_total=10000
          eof

          parameters = {
            :ensure  => 'present',
            :mode    => '0600',
            :owner   => 'nova',
            :group   => 'nova',
            :content => content,
          }
          is_expected.to contain_file('/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster1.conf') \
            .with(parameters).that_comes_before('Pcmk_resource[p_nova_compute_vmware_vcenter-srv_cluster1]')
        end

        it { is_expected.to contain_pcmk_resource('p_nova_compute_vmware_vcenter-srv_cluster1').with(
          :primitive_class    => 'ocf',
          :primitive_provider => 'fuel',
          :primitive_type     => 'nova-compute',
          :metadata           => {
            'resource-stickiness' => '1' },
          :parameters         => {
            'amqp_server_port'      => '5673',
            'config'                => '/etc/nova/nova.conf',
            'pid'                   => '/var/run/nova/nova-compute-vcenter-srv_cluster1.pid',
            'additional_parameters' => '--config-file=/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster1.conf', },
          :operations         => {
            'monitor'  => {
              'timeout'  => '10',
              'interval' => '20', },
            'start'    => {
              'timeout' => '30', },
            'stop'     => {
              'timeout' => '30', } },
        ).that_comes_before('Service[p_nova_compute_vmware_vcenter-srv_cluster1]') }

        it { is_expected.to contain_service('p_nova_compute_vmware_vcenter-srv_cluster1').with(
          :ensure => 'running',
          :enable => true,
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
            :target_node            => 'controllers',
            :vc_insecure            => true,
            :vc_ca_file             => '',
            :datastore_regex        => '.*',
          }
        end

        let(:title) { '1' }

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__compute__ha('1') }

        it { is_expected.to contain_file('/etc/nova/nova-compute.d').with(
          :ensure => 'directory',
          :owner  => 'nova',
          :group  => 'nova',
          :mode   => '0750',
        ).that_comes_before('File[/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster2.conf]') }

        it do
          content = <<-eof
[DEFAULT]

# Driver to use for controlling virtualization.
# Options include: libvirt.LibvirtDriver, xenapi.XenAPIDriver, fake.FakeDriver,
# ironic.IronicDriver, vmwareapi.VMwareVCDriver, hyperv.HyperVDriver
#compute_driver=None
compute_driver=vmwareapi.VMwareVCDriver

# Name of log file to output to. If no default is set, logging will go to
# stdout. This option is ignored if log_config_append is set.
#log_file=None
log_file=nova-compute-vmware-vcenter-srv_cluster2.log

# Name of this node. This can be an opaque identifier. It is not necessarily a
# hostname, FQDN, or IP address. However, the node name must be valid within an
# AMQP key, and if using ZeroMQ, a valid hostname, FQDN, or IP address.
#host=localhost
host=vcenter-srv_cluster2

# Amount of memory in MB to reserve for the host.
#reserved_host_memory_mb=512
reserved_host_memory_mb = 0

# Force injection to take place on a config drive.
#force_config_drive = False
force_config_drive=False


[vmware]

# The number of times we retry on failures, e.g., socket error, etc.
#api_retry_count=10
api_retry_count=5

# Specify a CA bundle file to use in verifying the vCenter server certificate.
#ca_file=None

# The prefix for where cached images are stored. This is NOT the full path -
# just a folder prefix. This should only be used when a datastore cache should
# be shared between compute nodes. Note: this should only be used when the
# compute nodes have a shared file system.
#cache_prefix=None
cache_prefix=$host

# Name of a VMware Cluster ComputeResource.
#cluster_name=None
cluster_name=Cluster2

# Set this value if affected by an increased network latency causing repeated
# characters when typing in a remote console.
#console_delay_seconds=None

# Regex to match the name of a datastore.
#datastore_regex=None
datastore_regex=.*

# Hostname or IP address for connection to VMware vCenter host.
#host_ip=None
host_ip=172.16.0.254

# Password for connection to VMware vCenter host.
#host_password=None
host_password=Qwer!1234

# Port for connection to VMware vCenter host.
#host_port = 443

# Username for connection to VMware vCenter host.
#host_username=None
host_username=administrator@vsphere.local

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "ca_file" is set.
#insecure = False
insecure=true

# This option should be configured only when using the NSX-MH Neutron plugin.
# This is the name of the integration bridge on the ESXi. This should not be set
# for any other Neutron plugin. Hence the default value is not set.
#integration_bridge=None

# The maximum number of ObjectContent data objects that should be returned in a
# single result. A positive value will cause the operation to suspend the
# retrieval when the count of objects reaches the specified maximum. The server
# may still limit the count to something less than the configured value. Any
# remaining objects may be retrieved with additional requests.
#maximum_objects = 100
maximum_objects=100

# The PBM default policy. If pbm_wsdl_location is set and there is no defined
# storage policy for the specific request then this policy will be used.
#pbm_default_policy=None

# The PBM status.
#pbm_enabled=False

# PBM service WSDL file location URL.
# e.g. file:///opt/SDK/spbm/wsdl/pbmService.wsdl Not setting this will disable
# storage policy based placement of instances.
#pbm_wsdl_location=None

# Identifies a proxy service that provides network access to the
# serial_port_service_uri. This option is ignored if serial_port_service_uri is
# not specified.
#serial_port_proxy_uri=None

# Identifies the remote system that serial port traffic will be sent to. If this
# is not set, no serial ports will be added to the created VMs.
#serial_port_service_uri=None

# The interval used for polling of remote tasks.
#task_poll_interval=0.5
task_poll_interval=5.0

# Whether to use linked clone
#use_linked_clone=True
use_linked_clone=true

# Optional VIM Service WSDL Location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds.
#wsdl_location=None

# Physical ethernet adapter name for vlan networking
#vlan_interface=vmnic0

# VNC starting port.
#vnc_port=5900

# Total number of VNC ports
#vnc_port_total=10000
          eof

          parameters = {
            :ensure  => 'present',
            :mode    => '0600',
            :owner   => 'nova',
            :group   => 'nova',
            :content => content,
          }
          is_expected.to contain_file('/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster2.conf') \
            .with(parameters).that_comes_before('Pcmk_resource[p_nova_compute_vmware_vcenter-srv_cluster2]')
        end

        it { is_expected.to contain_pcmk_resource('p_nova_compute_vmware_vcenter-srv_cluster2').with(
          :primitive_class    => 'ocf',
          :primitive_provider => 'fuel',
          :primitive_type     => 'nova-compute',
          :metadata           => {
            'resource-stickiness' => '1' },
          :parameters         => {
            'amqp_server_port'      => '5673',
            'config'                => '/etc/nova/nova.conf',
            'pid'                   => '/var/run/nova/nova-compute-vcenter-srv_cluster2.pid',
            'additional_parameters' => '--config-file=/etc/nova/nova-compute.d/vmware-vcenter_srv_cluster2.conf', },
          :operations         => {
            'monitor'  => {
              'timeout'  => '10',
              'interval' => '20', },
            'start'    => {
              'timeout' => '30', },
            'stop'     => {
              'timeout' => '30', } },
        ).that_comes_before('Service[p_nova_compute_vmware_vcenter-srv_cluster2]') }

        it { is_expected.to contain_service('p_nova_compute_vmware_vcenter-srv_cluster2').with(
          :ensure => 'running',
          :enable => true,
        ) }
      end

    end
  end
end
