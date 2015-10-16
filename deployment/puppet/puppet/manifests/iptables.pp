class puppet::iptables {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  puppet::access_to_puppet_port { "puppet_tcp":   port => '8140' }

}
