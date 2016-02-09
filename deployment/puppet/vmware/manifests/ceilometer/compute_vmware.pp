# == Class: vmware::ceilometer::compute_vmware

# Class configures ceilometer compute agent on compute-vmware node.
#
# It does the following:
# - configure keystone auth parameters
# - reload ceilometer polling agent service, package is already
#   installed by ceilometer-compute deployment task
#
# === Parameters
# [*availability_zone_name*]
#    (required) Availability zone name that will be used to form host parameter
# [*vc_cluster*]
#    (required) vCenter cluster name that is going to be monitored
# [*vc_host*]
#    (required) vCenter cluster name that is going to be monitored
# [*vc_user*]
#    (required) vCenter user name to use
# [*vc_password*]
#    (required) Password for above vCenter user
# [*service_name*]
#    (required) Parameter to form 'host' parameter
# [*target_node*]
#    (optional) Parameter that specifies on which node service will be placed
# [*datastore_regex*]
#    (optional) Regex which match datastore that will be used for openstack vms
# [*debug*]
#    (optional) Flag that turn debug logging
# [*identity_uri*]
#    (optional) URL to access Keystone service
# [*auth_user*]
#    (optional) Keystone user
# [*auth_password*]
#    (optional) Keystone password
# [*tenant*]
#    (optional) Admin tenant name
#
class vmware::ceilometer::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node     = undef,
  $datastore_regex = undef,
  $debug           = undef,
  $identity_uri    = undef,
  $auth_user       = undef,
  $auth_password   = undef,
  $tenant          = undef,
) {
  if $debug {
    # Enable debug for rabbit and vmware only
    $default_log_levels = 'amqp=DEBUG,amqplib=DEBUG,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=DEBUG'
  } else {
    $default_log_levels = 'amqp=WARN,amqplib=WARN,boto=WARN,qpid=WARN,sqlalchemy=WARN,suds=INFO,iso8601=WARN,requests.packages.urllib3.connectionpool=WARN,oslo.vmware=WARN'
  }

  ceilometer_config {
    'DEFAULT/default_log_levels':           value => $default_log_levels;
    'DEFAULT/hypervisor_inspector':         value => 'vsphere';
    'DEFAULT/host':                         value => "${availability_zone_name}-${service_name}";
    'vmware/host_ip':                       value => $vc_host;
    'vmware/host_username':                 value => $vc_user;
    'vmware/host_password':                 value => $vc_password;
    'keystone_authtoken/admin_user':        value => $auth_user;
    'keystone_authtoken/admin_password':    value => $auth_password;
    'keystone_authtoken/admin_tenant_name': value => $tenant;
    'keystone_authtoken/identity_uri':      value => $identity_uri;
  }

  include ceilometer::params

  package { 'ceilometer-polling':
    ensure => latest,
    name   => $::ceilometer::params::agent_polling_package_name,
  }
  service { 'ceilometer-polling':
    ensure => running,
    name   => $::ceilometer::params::agent_polling_service_name,
  }

  Ceilometer_config<| |> ~> Service['ceilometer-polling']
  Package['ceilometer-polling'] -> Service['ceilometer-polling']
}
