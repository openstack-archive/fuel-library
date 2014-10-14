# proxy to upstream keystone module
# but for HA

class keystone_ha inherits keystone {
  # Call as this calls from openstack::keystone
  # from ::openstack::keystone keystone calls like:
  #
  class { '::keystone':
    verbose             => $verbose,
    debug               => $debug,
    catalog_type        => 'sql',
    admin_token         => $admin_token,
    enabled             => $enabled,
    sql_connection      => $sql_conn,
    bind_host           => $bind_host,
    package_ensure      => $package_ensure,
    use_syslog          => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
    max_retries         => $max_retries,
    max_pool_size       => $max_pool_size,
    max_overflow        => $max_overflow,
    idle_timeout        => $idle_timeout,
    rabbit_password     => $rabbit_password,
    rabbit_userid       => $rabbit_userid,
    rabbit_hosts        => $rabbit_hosts,
    rabbit_virtual_host => $rabbit_virtual_host,
    memcache_servers    => $memcache_servers,
    memcache_server_port => $memcache_server_port,
  }

  cluster::corosync::cs_service {'p_keystone':
    ocf_script      => 'keystone_ha:keystone',  # module_name:script_filename
    csr_parameters  => {
      # 'os_auth_url' => $auth_url,
      # 'tenant'      => $admin_tenant_name,
      # 'username'    => $admin_user,
      # 'password'    => $admin_password,
    },
    csr_metadata    => { 'resource-stickiness' => '1' },
    csr_mon_intr    => '20',
    csr_mon_timeout => '10',
    csr_timeout     => '60',
    service_name    => $::keystone::params::service_name,
    package         => $::keystone::params::package_name,
    service_title   => 'keystone',
    primary         => $primary,
    hasrestart      => false,
  }

  # pacemaker resource will be started by native Servise['keystone'] action

  # Keystone::some::sub_part['xxx'] -> Cluster::corosync::Cs_service['p_keystone']
  # Servive['keystone'] -> Service['another_stuff']

}