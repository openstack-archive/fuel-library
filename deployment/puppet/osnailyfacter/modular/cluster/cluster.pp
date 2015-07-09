notice('MODULAR: cluster.pp')

prepare_network_config(hiera('network_scheme'))
$corosync_nodes = corosync_nodes(hiera('corosync_nodes'), 'mgmt/corosync')

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
