class zabbix::monitoring::haproxy_mon {

  include zabbix::params

  if defined(Class['haproxy']) {
    zabbix_template_link { "$zabbix::params::host_name Template App HAProxy":
      host => $zabbix::params::host_name,
      template => 'Template App HAProxy',
      api => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'haproxy.be.discovery':
        key     => 'haproxy.be.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -b';
      'haproxy.be':
        key     => 'haproxy.be[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.fe.discovery':
        key     => 'haproxy.fe.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -f';
      'haproxy.fe':
        key     => 'haproxy.fe[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
      'haproxy.sv.discovery':
        key     => 'haproxy.sv.discovery',
        command => '/etc/zabbix/scripts/haproxy.sh -s';
      'haproxy.sv':
        key     => 'haproxy.sv[*]',
        command => '/etc/zabbix/scripts/haproxy.sh -v $1';
    }
    #sudo::directive {'zabbix_socat':
    #  ensure  => present,
    #  content => 'zabbix ALL = NOPASSWD: /usr/bin/socat',
    #}
  }
}
