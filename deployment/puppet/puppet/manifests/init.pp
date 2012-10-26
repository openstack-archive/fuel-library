class puppet (
    $puppet_master_version  = $puppet::params::puppet_master_version,
    $enable_service = false
  ) inherits puppet::params  {
  anchor { "puppet-begin": }
  anchor { "puppet-end": }

  Anchor<| title == "puppet-begin" |> ->
  Class["puppet::selinux"] ->
  Class["puppet::iptables"] ->
  Class["puppet::master"] ->
  Anchor<| title == "puppet-end" |>
  
  class { "puppet::selinux": }

  class { "puppet::iptables": }
    
  class { "puppet::master":
      puppet_master_version => $puppet_master_version,
      enable_service => $enable_service,
  }

  
}
