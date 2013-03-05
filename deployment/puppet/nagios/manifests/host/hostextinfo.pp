define nagios::host::hostextinfo() {

  @@nagios_hostextinfo { $name:
    ensure          => present,
    host_name       => $::fqdn,
    notes           => $::lsbdistid,
    icon_image      => $nagios::params::icon_image,
    icon_image_alt  => $::lsbdistid,
    statusmap_image => $nagios::params::statusmap_image,
    vrml_image      => "${nagios::params::distro}.png",
    target          => "/etc/${nagios::params::masterdir}/${nagios::master_proj_name}/${::hostname}_hostextinfo.cfg",
  }
}
