import 'common/globals.pp'

if (!empty(filter_nodes($nodes_hash, 'role', 'ceph-osd')) or
$storage_hash['volumes_ceph'] or
$storage_hash['images_ceph'] or
$storage_hash['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if ($use_ceph) {
  if ($use_neutron) {
    $ceph_cluster_network = get_network_role_property('storage', 'cidr')
    $ceph_public_network  = get_network_role_property('management', 'cidr')
  } else {
    $ceph_cluster_network = hiera('storage_network_range')
    $ceph_public_network  = hiera('management_network_range')
  }

  $primary_mons   = $controller
  $primary_mon    = $controller[0]['name']
  class {'ceph':
    primary_mon            => $primary_mon,
    cluster_node_address   => $controller_node_public,
    use_rgw                => $storage_hash['objects_ceph'],
    glance_backend         => $glance_backend,
    rgw_pub_ip             => $controller_node_public,
    rgw_adm_ip             => $controller_node_address,
    rgw_int_ip             => $controller_node_address,
    cluster_network        => $ceph_cluster_network,
    public_network         => $ceph_public_network,
    swift_endpoint_port    => '6780',
    use_syslog             => $use_syslog,
    syslog_log_level       => $syslog_log_level,
    syslog_log_facility    => $syslog_log_facility_ceph,
  }
}
