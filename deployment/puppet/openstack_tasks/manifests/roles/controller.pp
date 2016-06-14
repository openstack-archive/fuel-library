class openstack_tasks::roles::controller {

  notice('MODULAR: roles/controller.pp')

  # Pulling hiera
  $primary_controller             = hiera('primary_controller')

  if $primary_controller {
    package { 'cirros-testvm' :
      ensure => 'installed',
      name   => 'cirros-testvm',
    }
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
