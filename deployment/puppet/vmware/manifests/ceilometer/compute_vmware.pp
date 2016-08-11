#
# Copyright 2016 Mirantis, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: vmware::ceilometer::compute_vmware
#
# Class configures ceilometer compute agent on compute-vmware node.
# It does the following:
#   - configure keystone auth parameters
#   - reload ceilometer polling agent service, package is already
#     installed by ceilometer-compute deployment task
#
# === Parameters
#
# [*availability_zone_name*]
#   (required) Availability zone name that will be used to form host parameter.
#
# [*vc_cluster*]
#   (required) vCenter cluster name that is going to be monitored.
#
# [*vc_host*]
#   (required) IP address of the VMware vSphere host.
#
# [*vc_user*]
#   (required) Username of VMware vSphere.
#
# [*vc_password*]
#   (required) Password of VMware vSphere.
#
# [*service_name*]
#   (required) Parameter to form 'host' parameter.
#
# [*target_node*]
#   (optional) Parameter that specifies on which node service will be placed.
#   Defaults to undef.
#
# [*vc_insecure*]
#   (optional) If true, the vCenter server certificate is not verified. If
#   false, then the default CA truststore is used for verification. This option
#   is ignored if “ca_file” is set.
#   Defaults to 'True'.
#
# [*vc_ca_file*]
#   (optional) The hash name of the CA bundle file and data in format of:
#   Example:
#   "{"vc_ca_file"=>{"content"=>"RSA", "name"=>"vcenter-ca.pem"}}"
#   Defaults to undef.
#
# [*datastore_regex*]
#   (optional) Regex which match datastore that will be used for openstack vms.
#   Defaults to undef.
#
# [*debug*]
#   (optional) Flag that turn debug logging.
#   Defaults to undef.
#
# [*identity_uri*]
#   (optional) URL to access Keystone service.
#   Defaults to undef.
#
# [*auth_user*]
#   (optional) Keystone user.
#   Defaults to undef.
#
# [*auth_password*]
#   (optional) Keystone password.
#   Defaults to undef.
#
# [*tenant*]
#   (optional) Admin tenant name.
#   Defaults to undef.
#
class vmware::ceilometer::compute_vmware(
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node     = undef,
  $vc_insecure     = true,
  $vc_ca_file      = undef,
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

  class { '::vmware::ssl::ssl':
      vc_insecure    => $vc_insecure,
      vc_ca_file     => $vc_ca_file,
      vc_ca_filepath => '/etc/ceilometer/vcenter-ca.pem',
  }

  $ceilometer_vcenter_ca_filepath   = $::vmware::ssl::ssl::vcenter_ca_filepath
  $ceilometer_vcenter_insecure_real = $::vmware::ssl::ssl::vcenter_insecure_real

  ceilometer_config {
    'DEFAULT/default_log_levels':           value => $default_log_levels;
    'DEFAULT/hypervisor_inspector':         value => 'vmware';
    'DEFAULT/host':                         value => "${availability_zone_name}-${service_name}";
    'vmware/host_ip':                       value => $vc_host;
    'vmware/host_username':                 value => $vc_user;
    'vmware/host_password':                 value => $vc_password;
    'vmware/ca_file':                       value => $ceilometer_vcenter_ca_filepath;
    'vmware/insecure':                      value => $ceilometer_vcenter_insecure_real;
    'keystone_authtoken/admin_user':        value => $auth_user;
    'keystone_authtoken/admin_password':    value => $auth_password;
    'keystone_authtoken/admin_tenant_name': value => $tenant;
    'keystone_authtoken/identity_uri':      value => $identity_uri;
  }

  include ::ceilometer::params

  package { 'ceilometer-polling':
    ensure => latest,
    name   => $::ceilometer::params::agent_polling_package_name,
  }
  service { 'ceilometer-polling':
    ensure => running,
    name   => $::ceilometer::params::agent_polling_service_name,
  }

  Ceilometer_config<| |> ~> Service['ceilometer-polling']
  Package['ceilometer-polling'] ~> Service['ceilometer-polling']
}
