define openstack::firewall::allow (
) {
  ::firewall { "100 snat for port $title":
    chain  => 'INPUT',
    action => 'accept',
    proto  => 'tcp',
    dport  => $title,
    table  => 'filter',
  }
}
