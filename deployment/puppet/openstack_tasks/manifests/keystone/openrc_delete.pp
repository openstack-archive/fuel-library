class openstack_tasks::keystone::openrc_delete {

  notice('MODULAR: keystone/openrc_delete.pp')

  file { '/root/openrc':
    ensure => absent,
  }

}
