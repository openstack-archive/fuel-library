class puppet (
  ) {
  anchor { "puppet-begin": }
  anchor { "puppet-end": }

  Anchor<| title == "puppet-begin" |> ->
  Class["selinux"] ->
  Class["puppet::iptables"] ->
  Class["puppet::master"] ->
  Anchor<| title == "puppet-end" |>

  
  class { 'selinux': mode => 'disabled',}

  class { "puppet::iptables": }

    
  class { "puppet::master":
      puppet_master_ports => "18140 18141 18142 18143",
  }

  
}
