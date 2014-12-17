import 'common/globals.pp'

if $mellanox_mode != 'disabled' {
  class { 'mellanox_openstack::ofed_recompile' :}
  if ($storage_hash['iser']) {
    class { 'mellanox_openstack::iser_rename' :
      storage_parent      => $neutron_mellanox['storage_parent'],
      iser_interface_name => $neutron_mellanox['iser_interface_name'],
    }
    Class['mellanox_openstack::ofed_recompile'] -> Class['mellanox_openstack::iser_rename']
  }

  if $role == 'controller' {
    if ($mellanox_mode == 'ethernet') {
      $test_vm_pkg = 'cirros-testvm-mellanox'
    } else {
      $test_vm_pkg = 'cirros-testvm'
    }

    if ($mellanox_mode == 'ethernet') {
      $ml2_eswitch = $neutron_mellanox['ml2_eswitch']
      class { 'mellanox_openstack::controller':
        eswitch_vnic_type            => $ml2_eswitch['vnic_type'],
        eswitch_apply_profile_patch  => $ml2_eswitch['apply_profile_patch'],
      }
    }
  }

  if $role == 'compute' {
    if $mellanox_mode == 'ethernet' {
      $net04_physnet = $neutron_config['predefined_networks']['net04']['L2']['physnet']
      class { 'mellanox_openstack::compute':
        physnet => $net04_physnet,
        physifc => $neutron_mellanox['physical_port'],
      }
    }
  }

  package { 'cirros-testvm' :
    ensure => 'installed',
    name   => $test_vm_pkg,
  }
}
