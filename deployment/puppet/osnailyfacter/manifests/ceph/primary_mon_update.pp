class osnailyfacter::ceph::primary_mon_update {

  notice('MODULAR: ceph/primary_mon_update.pp')
  $override_configuration = hiera_hash(configuration, {})
  create_resources(override_resources, $override_configuration)

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(values($mon_address_map), ',')
  $mon_hosts       = join(keys($mon_address_map), ',')

  $storage_hash = hiera('storage', {})

  if ($storage_hash['volumes_ceph'] or
      $storage_hash['images_ceph'] or
      $storage_hash['objects_ceph'] or
      $storage_hash['ephemeral_ceph']
  ) {
    ceph_config {
      'global/mon_host':            value => $mon_ips;
      'global/mon_initial_members': value => $mon_hosts;
    }
  }
}
