notice('MODULAR: cluster.pp')

if empty(intersection(hiera_array('roles'),hiera_array('corosync_roles'))) {
    fail('The node role is not in corosync roles')

prepare_network_config(hiera_hash('network_scheme'))

$corosync_nodes = corosync_nodes(
    get_nodes_hash_by_roles(
        hiera_hash('network_metadata'),
        hiera_array('corosync_roles')
    ),
    'mgmt/corosync'
)

class { 'cluster':
  internal_address => get_network_role_property('mgmt/corosync', 'ipaddr'),
  corosync_nodes   => $corosync_nodes,
}

pcmk_nodes { 'pacemaker' :
  nodes => $corosync_nodes,
  add_pacemaker_nodes => false,
}

Service <| title == 'corosync' |> {
  subscribe => File['/etc/corosync/service.d'],
  require   => File['/etc/corosync/corosync.conf'],
}

Service['corosync'] -> Pcmk_nodes<||>
Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>
