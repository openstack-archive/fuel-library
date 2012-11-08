class puppet::iptables {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}
  
  define access_to_puppet_port($port, $protocol='tcp') {
    $rule = "-p $protocol -m state --state NEW -m $protocol --dport $port -j ACCEPT"
    exec { "access_to_puppet_${protocol}_port: $port":
      command => "iptables -t filter -I INPUT 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\"",
      onlyif => "test -f /etc/init.d/iptables"
    }
  }

  access_to_puppet_port { "puppet_tcp":   port => '8140' }

}
