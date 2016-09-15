class openstack::checksum_udp ($port = '514') {

  Exec {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  case $operatingsystem {
    /(?i)(centos|redhat|oraclelinux)/ : {
      exec { "checksum_fill_udp":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport ${port} -j CHECKSUM --checksum-fill; iptables-save > /etc/sysconfig/iptables",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport ${port} -j CHECKSUM --checksum-fill\""
      }
    }
    /(?i)(debian|ubuntu)/ : {
      exec { "checksum_fill_udp":
        command => "iptables -t mangle -A POSTROUTING -p udp --dport ${port} -j CHECKSUM --checksum-fill; iptables-save -c > /etc/iptables.rules",
        unless  => "iptables -t mangle -S POSTROUTING | grep -q \"^-A POSTROUTING -p udp -m udp --dport ${port} -j CHECKSUM --checksum-fill\""
      }
    }
  }
}
