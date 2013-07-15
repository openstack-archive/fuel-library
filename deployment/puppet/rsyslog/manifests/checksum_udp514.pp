class rsyslog::checksum_udp514 () {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(centos|redhat)/ : {
      exec { "checksum_fill_udp514":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport 514 -j CHECKSUM --checksum-fill; /etc/init.d/iptables save",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport 514 -j CHECKSUM --checksum-fill\""
      }
    }
    /(?i)(debian|ubuntu)/ : {
      exec { "checksum_fill_udp514":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport 514 -j CHECKSUM --checksum-fill; iptables-save -c > /etc/iptables.rules",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport 514 -j CHECKSUM --checksum-fill\""
      }
    }
  }
}
