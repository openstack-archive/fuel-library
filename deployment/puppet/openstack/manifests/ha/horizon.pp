# HA configuration for OpenStack Horizon
class openstack::ha::horizon (
  $use_ssl = false,
) {

  openstack::ha::haproxy_service { 'horizon':
    order          => '015',
    listen_port    => 80,
    public         => true,
    internal       => false,
    define_cookies => true,

    haproxy_config_options => {
      'option'  => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
      'rspidel' => '^Set-cookie:\ IP=',
      'balance' => 'source',
      'mode'    => 'http',
      'cookie'  => 'SERVERID insert indirect nocache',
      'capture' => 'cookie vgnvisitor= len 32',
      'timeout' => ['client 3h', 'server 3h'],
    },

    balancermember_options => 'check inter 2000 fall 3',
  }

  if $use_ssl {
    openstack::ha::haproxy_service { 'horizon-ssl':
      order       => '017',
      listen_port => 443,
      public      => true,
      internal    => false,

      haproxy_config_options => {
        'option'      => ['ssl-hello-chk', 'tcpka'],
        'stick-table' => 'type ip size 200k expire 30m',
        'stick'       => 'on src',
        'balance'     => 'source',
        'timeout'     => ['client 3h', 'server 3h'],
        'mode'        => 'tcp',
      },

      balancermember_options => 'weight 1 check',
    }
  }
}
