notice('MODULAR: keystone.pp')

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$use_neutron           = hiera('use_neutron')
$use_syslog            = hiera('use_syslog', true)

$management_vip        = hiera('management_vip')
$public_vip            = hiera('public_vip')
$internal_address      = hiera('internal_address')
$syslog_log_facility   = hiera('syslog_log_facility_keystone')
$primary_controller    = hiera('primary_controller')
$controller_nodes      = hiera('controller_nodes')
$amqp_hosts            = hiera('amqp_hosts')

$neutron_hash          = hiera_hash('neutron_config', {})
$workloads_hash        = hiera_hash('workloads_collector', {})
$keystone_hash         = hiera_hash('keystone', {})
$access_hash           = hiera_hash('access', {})
$rabbit_hash           = hiera_hash('rabbit_hash', {})
$glance_hash           = hiera_hash('glance', {})
$nova_hash             = hiera_hash('nova', {})
$cinder_hash           = hiera_hash('cinder', {})
$ceilometer_hash       = hiera_hash('ceilometer', {})
$ldap_hash             = hiera_hash('ldap', {})

$db_type     = 'mysql'
$db_host     = $management_vip
$db_password = structure($keystone_hash, 'db_password')
$db_name     = 'keystone'
$db_user     = 'keystone'

$admin_token    = structure($keystone_hash, 'admin_token')
$admin_tenant   = structure($access_hash, 'tenant')
$admin_email    = structure($access_hash, 'email')
$admin_user     = structure($access_hash, 'user')
$admin_password = structure($access_hash, 'password')

$public_address   = $public_vip
$admin_address    = $management_vip
$public_bind_host = $internal_address
$admin_bind_host  = $internal_address

$memcache_servers     = $controller_nodes
$memcache_server_port = '11211'

$glance_user_name         = structure($glance_hash, 'user_name', 'glance')
$glance_user_password     = structure($glance_hash, 'user_password')

$nova_user_name           = structure($nova_hash, 'user_name', 'nova')
$nova_user_password       = structure($nova_hash, 'user_password')

$cinder_user_name         = structure($cinder_hash, 'user_name', 'cinder')
$cinder_user_password     = structure($cinder_hash, 'user_password')

$ceilometer_user_name     = structure($ceilometer_hash, 'user_name', 'ceilometer')
$ceilometer_user_password = structure($ceilometer_hash, 'user_password')

$neutron_user_name        = structure($neutron_hash, 'keystone/admin_name', 'neutron')
$neutron_user_password    = structure($neutron_hash, 'keystone/admin_password')

$ceilometer = structure($ceilometer_hash, 'enabled')
$cinder     = true
$enabled    = true
$ssl        = false

$rabbit_password     = structure($rabbit_hash, 'password')
$rabbit_user         = structure($rabbit_hash, 'user')
$rabbit_hosts        = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'

$max_pool_size = hiera('max_pool_size')
$max_overflow  = hiera('max_overflow')
$max_retries   = '-1'
$idle_timeout  = '3600'

$murano_settings_hash = hiera('murano_settings', {})
$murano_repo_url = structure($murano_settings_hash, 'murano_repo_url', 'http://storage.apps.openstack.org')

###############################################################################

####### KEYSTONE ###########
class { 'openstack::keystone':
  verbose                  => $verbose,
  debug                    => $debug,
  db_type                  => $db_type,
  db_host                  => $db_host,
  db_password              => $db_password,
  db_name                  => $db_name,
  db_user                  => $db_user,
  admin_token              => $admin_token,
  public_address           => $public_address,
  internal_address         => $management_vip, # send traffic through HAProxy
  admin_address            => $admin_address,
  glance_user_name         => $glance_user_name,
  glance_user_password     => $glance_user_password,
  nova_user_name           => $nova_user_name,
  nova_user_password       => $nova_user_password,
  cinder                   => $cinder,
  cinder_user_name         => $cinder_user_name,
  cinder_user_password     => $cinder_user_password,
  neutron                  => $use_neutron,
  neutron_user_name        => $neutron_user_name,
  neutron_user_password    => $neutron_user_password,
  ceilometer               => $ceilometer,
  ceilometer_user_name     => $ceilometer_user_name,
  ceilometer_user_password => $ceilometer_user_password,
  public_bind_host         => $public_bind_host,
  admin_bind_host          => $admin_bind_host,
  enabled                  => $enabled,
  use_syslog               => $use_syslog,
  syslog_log_facility      => $syslog_log_facility,
  memcache_servers         => $memcache_servers,
  memcache_server_port     => $memcache_server_port,
  max_retries              => $max_retries,
  max_pool_size            => $max_pool_size,
  max_overflow             => $max_overflow,
  rabbit_password          => $rabbit_password,
  rabbit_userid            => $rabbit_user,
  rabbit_hosts             => $rabbit_hosts,
  rabbit_virtual_host      => $rabbit_virtual_host,
  idle_timeout             => $idle_timeout,
}

####### WSGI ###########

#class { 'osnailyfacter::apache':
#  listen_ports => hiera_array('apache_ports', ['80', '8888']),
#}

# TODO: (adidenko) use file from package for Debian, when
# https://review.fuel-infra.org/6251 is merged.
#class { 'keystone::wsgi::apache':
#  priority => '05',
#  threads  => 1,
#  workers  => min(max($::processorcount,2), 24),
#  ssl      => $ssl,

#  wsgi_script_ensure => $::osfamily ? {
#    'RedHat'       => 'link',
#    default        => 'file',
#  },
#  wsgi_script_source => $::osfamily ? {
#  # 'Debian'      => '/usr/share/keystone/wsgi.py',
#    'RedHat'       => '/usr/share/keystone/keystone.wsgi',
#    default        => undef,
#  },
#}

#include ::tweaks::apache_wrappers

###############################################################################

class { 'keystone::roles::admin':
  admin        => $admin_user,
  password     => $admin_password,
  email        => $admin_email,
  admin_tenant => $admin_tenant,
}

class { 'openstack::auth_file':
  admin_user      => $admin_user,
  admin_password  => $admin_password,
  admin_tenant    => $admin_tenant,
  controller_node => $management_vip,
  murano_repo_url => $murano_repo_url,
}

class { 'openstack::workloads_collector':
  enabled               => structure($workloads_hash, 'enabled', false),
  workloads_username    => structure($workloads_hash, 'username'),
  workloads_password    => structure($workloads_hash, 'password'),
  workloads_tenant      => structure($workloads_hash, 'tenant'),
  workloads_create_user => structure($workloads_hash, 'create_user'),
}

Exec <| title == 'keystone-manage db_sync' |> ->
Class['keystone::roles::admin'] ->
Class['openstack::auth_file']

Class['keystone::roles::admin'] ->
Class['openstack::workloads_collector']

$haproxy_stats_url = "http://${management_vip}:10000/;csv"

haproxy_backend_status { 'keystone-public' :
  name => 'keystone-1',
  url  => $haproxy_stats_url,
}

haproxy_backend_status { 'keystone-admin' :
  name => 'keystone-2',
  url  => $haproxy_stats_url,
}

Service['keystone'] -> Haproxy_backend_status<||>
Service<| title == 'httpd' |> -> Haproxy_backend_status<||>
Haproxy_backend_status<||> -> Class['keystone::roles::admin']

case $::osfamily {
  'RedHat': {
    $pymemcache_package_name      = 'python-memcached'
  }
  'Debian': {
    $pymemcache_package_name      = 'python-memcache'
  }
  default: {
    fail("The ${::osfamily} operating system is not supported")
  }
}

package { 'python-memcache' :
  ensure => present,
  name   => $pymemcache_package_name,
}

Package['python-memcache'] -> Nova::Generic_service <||>

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'keystone':
    package_name => 'keystone',
  }
}

####### LDAP #######

if structure($ldap_hash, 'enabled', false) {

  class { 'keystone::ldap' :
    url                                 => structure($ldap_hash, 'url'),
    user                                => structure($ldap_hash, 'user'),
    password                            => structure($ldap_hash, 'password'),
    suffix                              => structure($ldap_hash, 'suffix'),
    query_scope                         => structure($ldap_hash, 'query_scope', 'sub'),
    page_size                           => structure($ldap_hash, 'page_size', '0'),

    user_tree_dn                        => structure($ldap_hash, 'user_tree_dn'),
    user_filter                         => structure($ldap_hash, 'user_filter', ''),
    user_objectclass                    => structure($ldap_hash, 'user_objectclass', 'person'),
    user_id_attribute                   => structure($ldap_hash, 'user_id_attribute', 'cn'),
    user_name_attribute                 => structure($ldap_hash, 'user_name_attribute', 'sAMAccountName'),
    user_mail_attribute                 => structure($ldap_hash, 'user_mail_attribute', 'mail'),
    user_enabled_attribute              => structure($ldap_hash, 'user_enabled_attribute', 'userAccountControl'),
    user_enabled_mask                   => structure($ldap_hash, 'user_enabled_mask', '2'),
    user_enabled_default                => structure($ldap_hash, 'user_enabled_default', '512'),
    user_attribute_ignore               => structure($ldap_hash, 'user_attribute_ignore', 'default_project_id,tenants,password'),
    user_default_project_id_attribute   => structure($ldap_hash, 'user_default_project_id_attribute'),
    user_allow_create                   => structure($ldap_hash, 'user_allow_create', false),
    user_allow_update                   => structure($ldap_hash, 'user_allow_update', false),
    user_allow_delete                   => structure($ldap_hash, 'user_allow_delete', false),
    user_pass_attribute                 => structure($ldap_hash, 'user_pass_attribute', ''),
    user_enabled_emulation              => structure($ldap_hash, 'user_enabled_emulation', false),
    user_enabled_emulation_dn           => structure($ldap_hash, 'user_enabled_emulation_dn', ''),
    user_additional_attribute_mapping   => structure($ldap_hash, 'user_additional_attribute_mapping', ''),

    tenant_tree_dn                      => structure($ldap_hash, 'tenant_tree_dn'),
    tenant_filter                       => structure($ldap_hash, 'tenant_filter'),
    tenant_objectclass                  => structure($ldap_hash, 'tenant_objectclass'),
    tenant_id_attribute                 => structure($ldap_hash, 'tenant_id_attribute'),
    tenant_member_attribute             => structure($ldap_hash, 'tenant_member_attribute'),
    tenant_desc_attribute               => structure($ldap_hash, 'tenant_desc_attribute'),
    tenant_name_attribute               => structure($ldap_hash, 'tenant_name_attribute'),
    tenant_enabled_attribute            => structure($ldap_hash, 'tenant_enabled_attribute'),
    tenant_domain_id_attribute          => structure($ldap_hash, 'tenant_domain_id_attribute'),
    tenant_attribute_ignore             => structure($ldap_hash, 'tenant_attribute_ignore'),
    tenant_allow_create                 => structure($ldap_hash, 'tenant_allow_create'),
    tenant_allow_update                 => structure($ldap_hash, 'tenant_allow_update'),
    tenant_allow_delete                 => structure($ldap_hash, 'tenant_allow_delete'),
    tenant_enabled_emulation            => structure($ldap_hash, 'tenant_enabled_emulation'),
    tenant_enabled_emulation_dn         => structure($ldap_hash, 'tenant_enabled_emulation_dn'),
    tenant_additional_attribute_mapping => structure($ldap_hash, 'tenant_additional_attribute_mapping'),

    role_tree_dn                        => structure($ldap_hash, 'role_tree_dn'),
    role_filter                         => structure($ldap_hash, 'role_filter'),
    role_objectclass                    => structure($ldap_hash, 'role_objectclass'),
    role_id_attribute                   => structure($ldap_hash, 'role_id_attribute'),
    role_name_attribute                 => structure($ldap_hash, 'role_name_attribute'),
    role_member_attribute               => structure($ldap_hash, 'role_member_attribute'),
    role_attribute_ignore               => structure($ldap_hash, 'role_attribute_ignore'),
    role_allow_create                   => structure($ldap_hash, 'role_allow_create'),
    role_allow_update                   => structure($ldap_hash, 'role_allow_update'),
    role_allow_delete                   => structure($ldap_hash, 'role_allow_delete'),
    role_additional_attribute_mapping   => structure($ldap_hash, 'role_additional_attribute_mapping'),

    group_tree_dn                       => structure($ldap_hash, 'group_tree_dn'),
    group_filter                        => structure($ldap_hash, 'group_filter'),
    group_objectclass                   => structure($ldap_hash, 'group_objectclass'),
    group_id_attribute                  => structure($ldap_hash, 'group_id_attribute'),
    group_name_attribute                => structure($ldap_hash, 'group_name_attribute'),
    group_member_attribute              => structure($ldap_hash, 'group_member_attribute'),
    group_desc_attribute                => structure($ldap_hash, 'group_desc_attribute'),
    group_attribute_ignore              => structure($ldap_hash, 'group_attribute_ignore'),
    group_allow_create                  => structure($ldap_hash, 'group_allow_create'),
    group_allow_update                  => structure($ldap_hash, 'group_allow_update'),
    group_allow_delete                  => structure($ldap_hash, 'group_allow_delete'),
    group_additional_attribute_mapping  => structure($ldap_hash, 'group_additional_attribute_mapping'),

    use_tls                             => structure($ldap_hash, 'use_tls', false),
    tls_cacertdir                       => structure($ldap_hash, 'tls_cacertdir'),
    tls_cacertfile                      => structure($ldap_hash, 'tls_cacertfile'),
    tls_req_cert                        => structure($ldap_hash, 'tls_req_cert'),

    identity_driver                     => structure($ldap_hash, 'identity_driver', 'keystone.identity.backends.ldap.Identity'),
    assignment_driver                   => structure($ldap_hash, 'assignment_driver', 'keystone.assignment.backends.sql.Assignment'),
  }
}
