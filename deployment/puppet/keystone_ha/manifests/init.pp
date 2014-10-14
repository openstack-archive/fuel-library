# proxy to upstream keystone module
# but for HA

class keystone_ha inherits keystone {

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