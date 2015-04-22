notice('MODULAR: cluster.pp')

$nodes = hiera('nodes')
$corosync_nodes = corosync_nodes($nodes)

class { '::cluster':
  internal_address  => hiera('internal_address'),
  unicast_addresses => ipsort(values($corosync_nodes)),
}

pcmk_nodes { 'pacemaker' :
  nodes => $corosync_nodes,
}

Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>
