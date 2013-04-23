
class openstack::firewall (
	$ssh_port = 22,
	$http_port = 80,
	$https_port = 443,
	$mysql_port = 3306,
	$mysql_backend_port = 3307,
  $mysql_gcomm_port = 4567,
  $galera_ist_port = 4568,
	$keystone_public_port =  5000,
	$swift_proxy_port =  8080,
	$swift_object_port =  6000,
	$swift_container_port =  6001,
	$swift_account_port =  6002,
  $keystone_admin_port = 35357,
	$glance_api_port = 9292,
	$glance_reg_port = 9191,
	$glance_nova_api_ec2_port = 8773,
	$nova_api_compute_port =   8774,
	$nova_api_metadata_port =  8775,
	$nova_api_volume_port =  8776,
	$nova_vncproxy_port =  6080,
	$erlang_epmd_port  =   4369,
	$erlang_rabbitmq_port =  5672,
  $erlang_inet_dist_port = 41055,
	$memcached_port =  11211,
  $rsync_port = 873,
  $iscsi_port = 3260,
	$quantum_api_port = 9696,
) {

#  file {"iptables":
#    path     => $operatingsystem ? {
#      /(Debian|Ubuntu)/ => '/etc/network/rules.v4',
#      /(RedHat|CentOS)/ => '/etc/sysconfig/iptables',
#      },
#    source => "puppet:///modules/openstack/iptables"
#  }->
#
#  exec { 'startup-firewall':
#    command     => $operatingsystem ? {
#      /(Debian|Ubuntu)/ => '/sbin/iptables-restore  /etc/network/rules.v4',
#      /(RedHat|CentOS)/ => '/sbin/iptables-restore  /etc/sysconfig/iptables',
#      }
#    }
#  }

  firewall { "000 accept all icmp requests":
    proto  => 'icmp',
    action => 'accept',
  }->

  firewall { '001 accept all to lo interface':
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }->

  firewall { '002 accept related established rules':
    proto   => 'all',
    state   => ['RELATED', 'ESTABLISHED'],
    action  => 'accept',
  }

  firewall {'020 ssh':
    port   => $ssh_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '100 http':
    port   => [$http_port, $https_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'101 mysql':
    port   => [$mysql_port, $mysql_backend_port, $mysql_gcomm_port, $galera_ist_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'102 keystone':
    port   => [$keystone_public_port,$keystone_admin_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'103 swift':
    port   => [$swift_proxy_port, $swift_object_port, $swift_container_port, $swift_account_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'104 glance':
    port   => [$glance_api_port, $glance_reg_port, $glance_nova_api_ec2_port,],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'105 nova ':
    port   => [$nova_api_compute_port,$nova_api_metadata_port,$nova_api_volume_port, $nova_vncproxy_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'106 rabbitmq ':
    port   => [$erlang_epmd_port, $erlang_rabbitmq_port, $erlang_inet_dist_port],
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'107 memcached ':
    port   => $memcached_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'108 rsync':
    port   => $rsync_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'109 iscsi ':
    port   => $iscsi_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall {'110 quantum ':
    port   => $quantum_api_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '999 drop all other requests':
    action => 'drop',
  }
  
}