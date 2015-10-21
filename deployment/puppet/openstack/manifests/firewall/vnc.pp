define openstack::firewall::vnc ($extra_net = $title) {
  firewall {"120 vnc ports $title":
    port   => '5900-6100',
    proto  => 'tcp',
    source => $extra_net,
    action => 'accept',
  }
}
