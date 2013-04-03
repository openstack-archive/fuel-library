define quantum::agents::sysctl (
  $before_package = $name,
){

  include 'quantum::params'

  if !defined(Sysctl::Value['net.ipv4.conf.all.arp_announce']) {
      sysctl::value { 'net.ipv4.conf.all.arp_announce': value => '2' }
  }

  if !defined(Sysctl::Value['net.ipv4.conf.all.arp_ignore']) {
      sysctl::value { 'net.ipv4.conf.all.arp_ignore': value => '2' }
  }

  if !defined(Sysctl::Value['net.ipv4.conf.all.arp_filter']) {
      sysctl::value { 'net.ipv4.conf.all.arp_filter': value => '1' }
  }

  Sysctl::Value['net.ipv4.conf.all.arp_announce'] -> 
    Sysctl::Value['net.ipv4.conf.all.arp_ignore'] -> 
      Sysctl::Value['net.ipv4.conf.all.arp_filter'] -> 
        Package <| title == $before_package |>

}