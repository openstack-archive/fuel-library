class ironic::rabbit (
  $configure_rabbit_server = false,
  $user                    = $::ironic::params::rabbit_userid,
  $password                = $::ironic::params::rabbit_password,
  $port                    = $::ironic::params::rabbit_port,
  $vhost                   = $::ironic::params::rabbit_vhost,
  ) inherits ironic::params {

  define ironic_access_to_rabbitmq_port ($port, $protocol = 'tcp') {
    $rule = "-p $protocol -m state --state NEW -m $protocol --dport $port -j ACCEPT"

    exec { "ironic_access_to_${protocol}_port: $port":
      command => "iptables -t filter -I INPUT 1 $rule; \
          /etc/init.d/iptables save",
      unless  => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\"",
      path    => '/bin:/usr/bin:/sbin:/usr/sbin',
    }
  }

  case $::osfamily {
    'Debian' : {
    }
    'RedHat' : {
      ironic_access_to_rabbitmq_port { "rabbit_tcp": port => $port }
    }
    default  : {
      fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
    }
  }

  if $configure_rabbit_server {
    class { 'rabbitmq::server':
      service_ensure     => 'running',
      delete_guest_user  => true,
      config_cluster     => false,
      cluster_disk_nodes => [],
    }
  }

  rabbitmq_user { $user:
    admin    => true,
    password => $password,
    provider => 'rabbitmqctl',
    require  => Class['rabbitmq::server'],
  }

  rabbitmq_user_permissions { "${user}@${vhost}":
    configure_permission => '.*',
    write_permission     => '.*',
    read_permission      => '.*',
    provider             => 'rabbitmqctl',
    require              => [Class['rabbitmq::server'], Rabbitmq_user[$user],]
  }

  rabbitmq_vhost { $vhost: }

  Rabbitmq_user <| |> -> Exec['ironic_rabbitmq_restart']
  Rabbitmq_user_permissions <| |> -> Exec['ironic_rabbitmq_restart']

  exec { 'ironic_rabbitmq_restart':
    command => 'service rabbitmq-server restart',
    path    => ['/bin', '/sbin', '/usr/bin', '/usr/sbin'],
  }

}
