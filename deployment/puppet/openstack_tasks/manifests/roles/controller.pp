class openstack_tasks::roles::controller {

  notice('MODULAR: roles/controller.pp')

  # Pulling hiera
  $primary_controller             = hiera('primary_controller')

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
      ram  => 64,
      disk => 0,
      vcpu => 1,
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

  # Reduce swapiness on controllers, see LP#1413702
  sysctl::value { 'vm.swappiness':
    value => '10'
  }

}
# vim: set ts=2 sw=2 et :
