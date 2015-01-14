# Workaround for fuel bug with firewall
firewall {'003 remote rabbitmq ':
  sport   => [ 4369, 5672, 15672, 41055, 55672, 61613 ],
  source  => hiera('master_ip'),
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

firewall {'004 remote puppet ':
  sport   => [ 8140 ],
  source  => hiera('master_ip'),
  proto   => 'tcp',
  action  => 'accept',
  require => Class['openstack::firewall'],
}

class { 'openstack::firewall' :
  nova_vnc_ip_range => hiera('management_network_range'),
}
