notice('MODULAR: controller.pp')

# Pulling hiera
$primary_controller             = hiera('primary_controller')
$neutron_mellanox               = hiera('neutron_mellanox', false)
$use_neutron                    = hiera('use_neutron', false)

# Do the stuff
if $neutron_mellanox {
  $mellanox_mode = $neutron_mellanox['plugin']
} else {
  $mellanox_mode = 'disabled'
}

if $primary_controller {
  if ($mellanox_mode == 'ethernet') {
    $test_vm_pkg = 'cirros-testvm-mellanox'
  } else {
    $test_vm_pkg = 'cirros-testvm'
  }
  package { 'cirros-testvm' :
    ensure => 'installed',
    name   => $test_vm_pkg,
  }
}

Exec { logoutput => true }

if ($::mellanox_mode == 'ethernet') {
  $ml2_eswitch = $neutron_mellanox['ml2_eswitch']
  class { 'mellanox_openstack::controller':
    eswitch_vnic_type           => $ml2_eswitch['vnic_type'],
    eswitch_apply_profile_patch => $ml2_eswitch['apply_profile_patch'],
  }
}

# NOTE(bogdando) for nodes with pacemaker, we should use OCF instead of monit

# BP https://blueprints.launchpad.net/mos/+spec/include-openstackclient
package { 'python-openstackclient' :
  ensure => installed,
}

# Reduce swapiness on controllers, see LP#1413702
sysctl::value { 'vm.swappiness':
  value => '10'
}

# vim: set ts=2 sw=2 et :
