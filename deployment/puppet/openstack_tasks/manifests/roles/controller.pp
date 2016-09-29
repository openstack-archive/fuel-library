class openstack_tasks::roles::controller {

  notice('MODULAR: roles/controller.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $primary_controller = hiera('primary_controller')
                                                                                               
  override_resources {'override-resources':
    configuration => $override_configuration,                                                  
    options       => $override_configuration_options,                                          
  }

  if $primary_controller {
    package { 'cirros-testvm' :
      ensure => 'installed',
      name   => 'cirros-testvm',
    }

    # create m1.micro flavor for OSTF
    include ::osnailyfacter::wait_for_keystone_backends
    class { '::osnailyfacter::wait_for_nova_backends':
      backends => ['nova-api']
    }

    nova_flavor { 'm1.micro':
      ensure => present,
      ram    => 64,
      disk   => 0,
      vcpus  => 1,
    }

    Class['::osnailyfacter::wait_for_keystone_backends'] ->
      Class['::osnailyfacter::wait_for_nova_backends'] ->
        Nova_flavor['m1.micro']
  }

  Exec { logoutput => true }

  # BP https://blueprints.launchpad.net/mos/+spec/include-openstackclient
  package { 'python-openstackclient' :
    ensure => installed,
  }

}
