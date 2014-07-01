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
  $wsdl_location=undef,
  $compute_driver='vmwareapi.VMwareVCDriver'
) {

  file {
    "/etc/nova/nova-compute.conf":
    content => template ("nova/nova-compute.conf.erb"),
    mode => 0644,
    owner => root,
    group => root,
    ensure => present,
  }

  package { 'python-suds':
    ensure   => present
  }
}
