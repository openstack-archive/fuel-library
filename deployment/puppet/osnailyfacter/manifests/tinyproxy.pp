class osnailyfacter::tinyproxy {
  # Allow connection to the tinyproxy for ostf tests
  firewall {'007 tinyproxy':
    dport   => [ 8888 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }
  package{'tinyproxy':} ->
  exec{'tinyproxy-init':
    command => "/bin/echo Allow $master_ip >> /etc/tinyproxy/tinyproxy.conf;
      /sbin/chkconfig tinyproxy on;
      /etc/init.d/tinyproxy restart;",
  }
}

