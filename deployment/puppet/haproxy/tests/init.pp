# Declare haproxy base class with configuration options
class { 'haproxy':
  enable                   => true,
  haproxy_global_options   => {'log'      => "${::ipaddress} local0",
                                'chroot'  => '/var/lib/haproxy',
                                'pidfile' => '/var/run/haproxy.pid',
                                'maxconn' => '4000',
                                'user'    => 'haproxy',
                                'group'   => 'haproxy',
                                'daemon'  => '',
                                'stats'   => 'socket /var/lib/haproxy/stats'
                              },
  haproxy_defaults_options => {'log'      => 'global',
                                'stats'   => 'enable',
                                'option'  => 'redispatch',
                                'retries' => '3',
                                'timeout' => ['http-request 10s',
                                'queue 1m',
                                'connect 10s',
                                'client 1m',
                                'server 1m',
                                'check 10s'],
                                'maxconn' => '8000'
                              },
}

# Export a balancermember server, note that the listening_service parameter
#  will/must correlate with an haproxy::config defined resource type.
@@haproxy::balancermember { $fqdn:
  order                  => '21',
  listening_service      => 'puppet00',
  balancer_port          => '8140',
  balancermember_options => 'check',
  define_cookies         =>  true
}

# Declare a couple of Listening Services for haproxy.cfg
#  Note that the balancermember server resources are being collected in
#  the haproxy::config defined resource type with the following line:
#  Haproxy::Balancermember <<| listening_service == $name |>>
haproxy::config { 'puppet00':
  order                  => '20',
  virtual_ips             => [$::ipaddress],
  virtual_ip_port        => '18140',
  haproxy_config_options => {
    'option' => ['tcplog', 'ssl-hello-chk'], 'balance' => 'roundrobin' },
}
haproxy::config { 'stats':
  order                  => '30',
  virtual_ips             => [],
  virtual_ip_port        => '9090',
  haproxy_config_options => { 'mode'  => 'http',
                              'stats' => ['uri /', 'auth puppet:puppet']
  },
}
