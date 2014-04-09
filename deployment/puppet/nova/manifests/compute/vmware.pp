#
# Configure the VMware compute driver for nova.
#
# === Parameters
#
# [*host_ip*]
#   The IP address of the VMware vCenter server.
#
# [*host_username*]
#   The username for connection to VMware vCenter server.
#
# [*host_password*]
#   The password for connection to VMware vCenter server.
#
# [*cluster_name*]
#   The name of a vCenter cluster compute resource.
#
# [*api_retry_count*]
#   (optional) The number of times we retry on failures,
#   e.g., socket error, etc.
#   Defaults to 5.
#
# [*maximum_objects*]
#   (optional) The maximum number of ObjectContent data objects that should
#   be returned in a single result. A positive value will cause
#   the operation to suspend the retrieval when the count of
#   objects reaches the specified maximum. The server may still
#   limit the count to something less than the configured value.
#   Any remaining objects may be retrieved with additional requests.
#   Defaults to 100.
#
# [*task_poll_interval*]
#   (optional) The interval in seconds used for polling of remote tasks.
#   Defaults to 5.0
#
# [*use_linked_clone*]
#   (optional) Whether to use linked clone strategy while creating VM's.
#   Defaults to true.
#
# [*wsdl_location*]
#   (optional) VIM Service WSDL Location e.g
#   http://<server>/vimService.wsdl. Optional over-ride to
#   default location for bug work-arounds.
#   Defaults to None.
#

class nova::compute::vmware(
  $host_ip,
  $host_username,
  $host_password,
  $cluster_name,
  $api_retry_count=5,
  $maximum_objects=100,
  $task_poll_interval=5.0,
  $use_linked_clone=true,
  $wsdl_location=undef
) {

  nova_config {
    'DEFAULT/compute_driver':      value => 'vmwareapi.VMwareVCDriver';
    'VMWARE/host_ip':              value => $host_ip;
    'VMWARE/host_username':        value => $host_username;
    'VMWARE/host_password':        value => $host_password;
    'VMWARE/cluster_name':         value => $cluster_name;
    'VMWARE/api_retry_count' :     value => $api_retry_count;
    'VMWARE/maximum_objects' :     value => $maximum_objects;
    'VMWARE/task_poll_interval' :  value => $task_poll_interval;
    'VMWARE/use_linked_clone':     value => $use_linked_clone;
  }

  if $wsdl_location {
    nova_config {
      'VMWARE/wsdl_location' : value => $wsdl_location;
    }
  }

  package { 'python-suds':
    ensure   => present
  }
}
