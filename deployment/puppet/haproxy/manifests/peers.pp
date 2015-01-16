define haproxy::peers (
  $collect_exported = true,
) {

  # Template uses: $name, $ipaddress, $ports, $options
  concat::fragment { "${name}_peers_block":
    order   => "30-peers-00-${name}",
    target  => '/etc/haproxy/haproxy.cfg',
    content => template('haproxy/haproxy_peers_block.erb'),
  }

  if $collect_exported {
    haproxy::peer::collect_exported { $name: }
  }
  # else: the resources have been created and they introduced their
  # concat fragments. We don't have to do anything about them.
}
