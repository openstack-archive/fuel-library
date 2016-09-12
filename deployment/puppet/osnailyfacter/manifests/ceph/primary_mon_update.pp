class osnailyfacter::ceph::primary_mon_update {

  notice('MODULAR: ceph/primary_mon_update.pp')
  $override_configuration = hiera_hash(configuration, {})
  $override_configuration_options = hiera_hash(configuration_options, {})

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(sorted_hosts($mon_address_map, 'ip'), ',')
  $mon_hosts       = join(sorted_hosts($mon_address_map, 'host'), ',')

  $storage_hash = hiera('storage', {})

  override_resources {'override-resources':
    configuration => $override_configuration,
    options       => $override_configuration_options,
  }

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
