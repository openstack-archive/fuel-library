notice('MODULAR: keystone.pp')

$verbose               = hiera('verbose', true)
$debug                 = hiera('debug', false)
$use_neutron           = hiera('use_neutron')
$use_syslog            = hiera('use_syslog', true)
$keystone_hash         = hiera('keystone')
$access_hash           = hiera('access')
$management_vip        = hiera('management_vip')
$public_vip            = hiera('public_vip')
$internal_address      = hiera('internal_address')
$glance_hash           = hiera('glance')
$nova_hash             = hiera('nova')
$cinder_hash           = hiera('cinder')
$ceilometer_hash       = hiera('ceilometer')
$syslog_log_facility   = hiera('syslog_log_facility_keystone')
$rabbit_hash           = hiera('rabbit_hash')
$amqp_hosts            = hiera('amqp_hosts')
$primary_controller    = hiera('primary_controller')
$controller_nodes      = hiera('controller_nodes')
$neutron_user_password = hiera('neutron_user_password', false)
$workloads_hash        = hiera('workloads_collector', {})
$ldap_hash             = hiera('ldap', {})

$db_type     = 'mysql'
$db_host     = $management_vip
$db_password = $keystone_hash['db_password']
$db_name     = 'keystone'
$db_user     = 'keystone'

$admin_token    = $keystone_hash['admin_token']
$admin_tenant   = $access_hash['tenant']
$admin_email    = $access_hash['email']
$admin_user     = $access_hash['user']
$admin_password = $access_hash['password']

$public_address   = $public_vip
$admin_address    = $management_vip
$public_bind_host = $internal_address
$admin_bind_host  = $internal_address

$memcache_servers     = $controller_nodes
$memcache_server_port = '11211'

$glance_user_password     = $glance_hash['user_password']
$nova_user_password       = $nova_hash['user_password']
$cinder_user_password     = $cinder_hash['user_password']
$ceilometer_user_password = $ceilometer_hash['user_password']

$cinder = true
$ceilometer = $ceilometer_hash['enabled']
$enabled = true
$ssl = false

$rabbit_password     = $rabbit_hash['password']
$rabbit_user         = $rabbit_hash['user']
$rabbit_hosts        = split($amqp_hosts, ',')
$rabbit_virtual_host = '/'

$max_pool_size = hiera('max_pool_size')
$max_overflow  = hiera('max_overflow')
$max_retries   = '-1'
$idle_timeout  = '3600'

$murano_settings_hash = hiera('murano_settings', {})
if has_key($murano_settings_hash, 'murano_repo_url') {
  $murano_repo_url = $murano_settings_hash['murano_repo_url']
} else {
  $murano_repo_url = 'http://storage.apps.openstack.org'
}

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
  glance_user_password     => $glance_user_password,
  nova_user_password       => $nova_user_password,
  cinder                   => $cinder,
  cinder_user_password     => $cinder_user_password,
  neutron                  => $use_neutron,
  neutron_user_password    => $neutron_user_password,
  ceilometer               => $ceilometer,
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
  enabled               => $workloads_hash['enabled'],
  workloads_username    => $workloads_hash['username'],
  workloads_password    => $workloads_hash['password'],
  workloads_tenant      => $workloads_hash['tenant'],
  workloads_create_user => $workloads_hash['create_user'],
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

if $ldap_hash['enabled'] {
  class { 'keystone::ldap' :
    url                                 => $ldap_hash['url'],
    user                                => $ldap_hash['user'],
    password                            => $ldap_hash['password'],
    suffix                              => $ldap_hash['suffix'],
    query_scope                         => $ldap_hash['query_scope'],
    page_size                           => $ldap_hash['page_size'],

    user_tree_dn                        => $ldap_hash['user_tree_dn'],
    user_filter                         => $ldap_hash['user_filter'],
    user_objectclass                    => $ldap_hash['user_objectclass'],
    user_id_attribute                   => $ldap_hash['user_id_attribute'],
    user_name_attribute                 => $ldap_hash['user_name_attribute'],
    user_mail_attribute                 => $ldap_hash['user_mail_attribute'],
    user_enabled_attribute              => $ldap_hash['user_enabled_attribute'],
    user_enabled_mask                   => $ldap_hash['user_enabled_mask'],
    user_enabled_default                => $ldap_hash['user_enabled_default'],
    user_attribute_ignore               => $ldap_hash['user_attribute_ignore'],
    user_default_project_id_attribute   => $ldap_hash['user_default_project_id_attribute'],
    user_allow_create                   => $ldap_hash['user_allow_create'],
    user_allow_update                   => $ldap_hash['user_allow_update'],
    user_allow_delete                   => $ldap_hash['user_allow_delete'],
    user_pass_attribute                 => $ldap_hash['user_pass_attribute'],
    user_enabled_emulation              => $ldap_hash['user_enabled_emulation'],
    user_enabled_emulation_dn           => $ldap_hash['user_enabled_emulation_dn'],
    user_additional_attribute_mapping   => $ldap_hash['user_additional_attribute_mapping'],

    tenant_tree_dn                      => $ldap_hash['tenant_tree_dn'],
    tenant_filter                       => $ldap_hash['tenant_filter'],
    tenant_objectclass                  => $ldap_hash['tenant_objectclass'],
    tenant_id_attribute                 => $ldap_hash['tenant_id_attribute'],
    tenant_member_attribute             => $ldap_hash['tenant_member_attribute'],
    tenant_desc_attribute               => $ldap_hash['tenant_desc_attribute'],
    tenant_name_attribute               => $ldap_hash['tenant_name_attribute'],
    tenant_enabled_attribute            => $ldap_hash['tenant_enabled_attribute'],
    tenant_domain_id_attribute          => $ldap_hash['tenant_domain_id_attribute'],
    tenant_attribute_ignore             => $ldap_hash['tenant_attribute_ignore'],
    tenant_allow_create                 => $ldap_hash['tenant_allow_create'],
    tenant_allow_update                 => $ldap_hash['tenant_allow_update'],
    tenant_allow_delete                 => $ldap_hash['tenant_allow_delete'],
    tenant_enabled_emulation            => $ldap_hash['tenant_enabled_emulation'],
    tenant_enabled_emulation_dn         => $ldap_hash['tenant_enabled_emulation_dn'],
    tenant_additional_attribute_mapping => $ldap_hash['tenant_additional_attribute_mapping'],

    role_tree_dn                        => $ldap_hash['role_tree_dn'],
    role_filter                         => $ldap_hash['role_filter'],
    role_objectclass                    => $ldap_hash['role_objectclass'],
    role_id_attribute                   => $ldap_hash['role_id_attribute'],
    role_name_attribute                 => $ldap_hash['role_name_attribute'],
    role_member_attribute               => $ldap_hash['role_member_attribute'],
    role_attribute_ignore               => $ldap_hash['role_attribute_ignore'],
    role_allow_create                   => $ldap_hash['role_allow_create'],
    role_allow_update                   => $ldap_hash['role_allow_update'],
    role_allow_delete                   => $ldap_hash['role_allow_delete'],
    role_additional_attribute_mapping   => $ldap_hash['role_additional_attribute_mapping'],

    group_tree_dn                       => $ldap_hash['group_tree_dn'],
    group_filter                        => $ldap_hash['group_filter'],
    group_objectclass                   => $ldap_hash['group_objectclass'],
    group_id_attribute                  => $ldap_hash['group_id_attribute'],
    group_name_attribute                => $ldap_hash['group_name_attribute'],
    group_member_attribute              => $ldap_hash['group_member_attribute'],
    group_desc_attribute                => $ldap_hash['group_desc_attribute'],
    group_attribute_ignore              => $ldap_hash['group_attribute_ignore'],
    group_allow_create                  => $ldap_hash['group_allow_create'],
    group_allow_update                  => $ldap_hash['group_allow_update'],
    group_allow_delete                  => $ldap_hash['group_allow_delete'],
    group_additional_attribute_mapping  => $ldap_hash['group_additional_attribute_mapping'],

    tenant_tree_dn                      => $ldap_hash['tenant_tree_dn'],
    role_tree_dn                        => $ldap_hash['role_tree_dn'],

    use_tls                             => $ldap_hash['use_tls'],
    tls_cacertdir                       => $ldap_hash['tls_cacertdir'],
    tls_cacertfile                      => $ldap_hash['tls_cacertfile'],
    tls_req_cert                        => $ldap_hash['tls_req_cert'],

    identity_driver                     => 'keystone.identity.backends.ldap.Identity',
    assignment_driver                   => 'keystone.assignment.backends.sql.Assignment',
  }
}