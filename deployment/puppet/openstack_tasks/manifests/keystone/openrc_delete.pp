class openstack_tasks::keystone::openrc_delete {

  notice('MODULAR: keystone/openrc_delete.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  file { '/root/openrc':
    ensure => absent,
  }

}
