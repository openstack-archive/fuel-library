define openstack::firewall::vnc ($net = $title) {
  firewall {"120 vnc ports for $title":
    port   => '5900-6100',
    proto  => 'tcp',
    source => $net,
    action => 'accept',
  }
}
