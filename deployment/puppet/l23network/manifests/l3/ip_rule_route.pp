#Creates ML3 required default routes for interfaces to reply to
define l23network::l3::ip_rule_route (
  $interface,
  $ipaddr,
  $netmask,
  $gateway,
  $table
  ) {

  Exec {path  => '/bin:/usr/bin:/sbin:/usr/sbin'}

  if ($table == $interface) {
    exec {"create table ${interface}":
      command => "echo \$(expr \$(grep ^[1-9] /etc/iproute2/rt_tables | sort -nr | awk '{print \$1}' | tail -1 ) - 1) ${interface} >> /etc/iproute2/rt_tables",
      unless  => "grep -q ${interface} /etc/iproute2/rt_tables",
      before  => Exec["set ip route default ${gateway} dev ${interface} table ${table}"]
    }
  }

  exec {"set ip route default ${gateway} dev ${interface} table ${table}":
    command => "ip route replace default via ${gateway} dev ${interface} table ${table}",
    before  => Exec["set ip rule ${interface} table ${table}"]
  }

  exec {"set ip rule ${interface} table ${table}":
    command => "ip rule add from ${ipaddr}/${netmask} table ${table}",
    unless  => "ip rule | grep -q ${ipaddr}"
  }

}