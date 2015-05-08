notice('MODULAR: cluster.pp')

$nodes = hiera('nodes')
$corosync_nodes = corosync_nodes($nodes)
$internal_address = hiera('internal_address')

class { 'cluster':
  internal_address => $internal_address,
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
