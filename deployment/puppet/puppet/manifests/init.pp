class puppetmaster (
  ) {
  anchor { "puppetmaster-begin": }
  anchor { "puppetmaster-end": }

  Anchor<| title == "puppetmaster-begin" |> ->
  Class["selinux"] ->
  Class["puppetmaster::iptables"] ->
  Class["puppetmaster::master"] ->
  Anchor<| title == "puppetmaster-end" |>

  
  class { 'selinux': mode => 'disabled',}

  class { "puppetmaster::iptables": }

    
  class { "puppetmaster::master":
      puppet_master_ports => "18140 18141 18142 18143",
  }

  
}
