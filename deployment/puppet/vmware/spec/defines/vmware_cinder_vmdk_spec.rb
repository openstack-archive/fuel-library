require 'spec_helper'

describe 'vmware::cinder::vmdk', type: :define do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      context 'with default parameters' do
        let(:title) do
          'non-nova'
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__cinder__vmdk('non-nova') }

        it { is_expected.to contain_file('/etc/cinder/cinder.d') }

        it { is_expected.to contain_service('cinder_volume_vmware') }

        it do
          content = <<-eof
[DEFAULT]

# A list of backend names to use. These backend names should be backed by a
# unique [CONFIG] group with its options (list value)
#enabled_backends = <None>
enabled_backends=VMwareVcVmdk-backend

# Availability zone of this node (string value)
#storage_availability_zone = nova
storage_availability_zone=non-nova-cinder

# Default availability zone for new volumes. If not set, the
# storage_availability_zone option value is used as the default for new volumes.
# (string value)
#default_availability_zone = <None>
default_availability_zone=non-nova-cinder

# If set to true, the logging level will be set to DEBUG instead of the default
# INFO level. (boolean value)
#debug = false
debug=false


[VMwareVcVmdk-backend]
# Backend override of host value. (string value)
# Deprecated group/name - [DEFAULT]/host
#backend_host = <None>
backend_host=non-nova

# The backend name for a given driver implementation (string value)
#volume_backend_name = <None>
volume_backend_name=VMwareVcVmdk-backend

# Driver to use for volume creation (string value)
#volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_driver=cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver

# Number of times VMware vCenter server API must be retried upon connection
# related issues. (integer value)
#vmware_api_retry_count = 10
vmware_api_retry_count=10

# CA bundle file to use in verifying the vCenter server certificate. (string
# value)
#vmware_ca_file = <None>

# Name of a vCenter compute cluster where volumes should be created. (multi
# valued)
#vmware_cluster_name =

# IP address for connecting to VMware vCenter server. (string value)
#vmware_host_ip = <None>
vmware_host_ip=1.2.3.4

# Password for authenticating with VMware vCenter server. (string value)
#vmware_host_password = <None>
vmware_host_password=

# Username for authenticating with VMware vCenter server. (string value)
#vmware_host_username = <None>
vmware_host_username=administrator@vsphere.local

# Optional string specifying the VMware vCenter server version. The driver
# attempts to retrieve the version from VMware vCenter server. Set this
# configuration only if you want to override the vCenter server version. (string
# value)
#vmware_host_version = <None>


# Timeout in seconds for VMDK volume transfer between Cinder and Glance.
# (integer value)
#vmware_image_transfer_timeout_secs = 7200
vmware_image_transfer_timeout_secs=7200

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "vmware_ca_file" is set. (boolean value)
#vmware_insecure = false
vmware_insecure = True

# Max number of objects to be retrieved per batch. Query results will be
# obtained in batches from the server and not in one shot. Server may still
# limit the count to something less than the configured value. (integer value)
#vmware_max_objects_retrieval = 100
vmware_max_objects_retrieval=100

# The interval (in seconds) for polling remote tasks invoked on VMware vCenter
# server. (floating point value)
#vmware_task_poll_interval = 0.5
vmware_task_poll_interval=5

# Directory where virtual disks are stored during volume backup and restore.
# (string value)
#vmware_tmp_dir = /tmp
vmware_tmp_dir=/tmp

# Name of the vCenter inventory folder that will contain Cinder volumes. This
# folder will be created under "OpenStack/<project_folder>", where
# project_folder is of format "Project (<volume_project_id>)". (string value)
#vmware_volume_folder = Volumes
vmware_volume_folder=cinder-volumes

# Optional VIM service WSDL Location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds. (string value)
#vmware_wsdl_location = <None>

          eof

          parameters = {
              :ensure => 'present',
              :mode => '0600',
              :owner => 'cinder',
              :group => 'cinder',
              :content => content,
          }
          is_expected.to contain_file('/etc/cinder/cinder.d/vmware-non-nova.conf').with(parameters)
        end

      end

      context 'with custom parameters' do
        let(:params) do
          {
              :availability_zone_name => 'vcenter',
              :vc_host => '172.16.0.254',
              :vc_password => 'Qwer!1234',
              :vc_user => 'administrator@vsphere.local',
              :debug => false,
          }
        end

        let(:title) do
          params[:availability_zone_name]
        end

        it { is_expected.to compile.with_all_deps }

        it { is_expected.to contain_vmware__cinder__vmdk('vcenter') }

        it { is_expected.to contain_file('/etc/cinder/cinder.d') }

        it { is_expected.to contain_service('cinder_volume_vmware') }

        it do
          content = <<-eof
[DEFAULT]

# A list of backend names to use. These backend names should be backed by a
# unique [CONFIG] group with its options (list value)
#enabled_backends = <None>
enabled_backends=VMwareVcVmdk-backend

# Availability zone of this node (string value)
#storage_availability_zone = nova
storage_availability_zone=vcenter-cinder

# Default availability zone for new volumes. If not set, the
# storage_availability_zone option value is used as the default for new volumes.
# (string value)
#default_availability_zone = <None>
default_availability_zone=vcenter-cinder

# If set to true, the logging level will be set to DEBUG instead of the default
# INFO level. (boolean value)
#debug = false
debug=false


[VMwareVcVmdk-backend]
# Backend override of host value. (string value)
# Deprecated group/name - [DEFAULT]/host
#backend_host = <None>
backend_host=vcenter

# The backend name for a given driver implementation (string value)
#volume_backend_name = <None>
volume_backend_name=VMwareVcVmdk-backend

# Driver to use for volume creation (string value)
#volume_driver = cinder.volume.drivers.lvm.LVMVolumeDriver
volume_driver=cinder.volume.drivers.vmware.vmdk.VMwareVcVmdkDriver

# Number of times VMware vCenter server API must be retried upon connection
# related issues. (integer value)
#vmware_api_retry_count = 10
vmware_api_retry_count=10

# CA bundle file to use in verifying the vCenter server certificate. (string
# value)
#vmware_ca_file = <None>

# Name of a vCenter compute cluster where volumes should be created. (multi
# valued)
#vmware_cluster_name =

# IP address for connecting to VMware vCenter server. (string value)
#vmware_host_ip = <None>
vmware_host_ip=172.16.0.254

# Password for authenticating with VMware vCenter server. (string value)
#vmware_host_password = <None>
vmware_host_password=Qwer!1234

# Username for authenticating with VMware vCenter server. (string value)
#vmware_host_username = <None>
vmware_host_username=administrator@vsphere.local

# Optional string specifying the VMware vCenter server version. The driver
# attempts to retrieve the version from VMware vCenter server. Set this
# configuration only if you want to override the vCenter server version. (string
# value)
#vmware_host_version = <None>


# Timeout in seconds for VMDK volume transfer between Cinder and Glance.
# (integer value)
#vmware_image_transfer_timeout_secs = 7200
vmware_image_transfer_timeout_secs=7200

# If true, the vCenter server certificate is not verified. If false, then the
# default CA truststore is used for verification. This option is ignored if
# "vmware_ca_file" is set. (boolean value)
#vmware_insecure = false
vmware_insecure = True

# Max number of objects to be retrieved per batch. Query results will be
# obtained in batches from the server and not in one shot. Server may still
# limit the count to something less than the configured value. (integer value)
#vmware_max_objects_retrieval = 100
vmware_max_objects_retrieval=100

# The interval (in seconds) for polling remote tasks invoked on VMware vCenter
# server. (floating point value)
#vmware_task_poll_interval = 0.5
vmware_task_poll_interval=5

# Directory where virtual disks are stored during volume backup and restore.
# (string value)
#vmware_tmp_dir = /tmp
vmware_tmp_dir=/tmp

# Name of the vCenter inventory folder that will contain Cinder volumes. This
# folder will be created under "OpenStack/<project_folder>", where
# project_folder is of format "Project (<volume_project_id>)". (string value)
#vmware_volume_folder = Volumes
vmware_volume_folder=cinder-volumes

# Optional VIM service WSDL Location e.g http://<server>/vimService.wsdl.
# Optional over-ride to default location for bug work-arounds. (string value)
#vmware_wsdl_location = <None>

          eof

          parameters = {
              :ensure => 'present',
              :mode => '0600',
              :owner => 'cinder',
              :group => 'cinder',
              :content => content,
          }
          is_expected.to contain_file('/etc/cinder/cinder.d/vmware-vcenter.conf').with(parameters)
        end

      end

    end
  end
end