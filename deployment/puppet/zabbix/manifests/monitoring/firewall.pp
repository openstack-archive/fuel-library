class zabbix::monitoring::firewall inherits zabbix::params {
  $enabled = true

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App Iptables Stats":
      host => $host_name,
      template => 'Template App Iptables Stats',
      api => $api_hash,
    }
    package { 'iptstate':
      ensure => present;
    }
#    sudo::directive {'iptstate_users':
#      ensure  => present,
#      content => 'zabbix ALL = NOPASSWD: /usr/sbin/iptstate',
#    }
    zabbix::agent::userparameter {
      'iptstate.tcp':
        command => 'sudo iptstate -1 | grep tcp | wc -l';
      'iptstate.tcp.syn':
        command => 'sudo iptstate -1 | grep SYN | wc -l';
      'iptstate.tcp.timewait':
        command => 'sudo iptstate -1 | grep TIME_WAIT | wc -l';
      'iptstate.tcp.established':
        command => 'sudo iptstate -1 | grep ESTABLISHED | wc -l';
      'iptstate.tcp.close':
        command => 'sudo iptstate -1 | grep CLOSE | wc -l';
      'iptstate.udp':
        command => 'sudo iptstate -1 | grep udp | wc -l';
      'iptstate.icmp':
        command => 'sudo iptstate -1 | grep icmp | wc -l';
      'iptstate.other':
        command => 'sudo iptstate -1 -t | head -2 |tail -1 | sed -e \'s/^.*Other: \(.*\) (.*/\1/\''
    }
  }
}
