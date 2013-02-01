define nagios::host::hostextinfo() {

  @@nagios_hostextinfo { $name:
    ensure          => present,
    host_name       => $::fqdn,
    notes           => $::lsbdistid,
    icon_image      => "base/${nagios::params::distro}.png",
    icon_image_alt  => $::lsbdistid,
    statusmap_image => "base/${nagios::params::distro}.gd2",
    vrml_image      => "${nagios::params::distro}.png",
    target          => "/etc/${nagios::params::masterdir}/${proj_name}/${::hostname}_hostextinfo.cfg",
  }
}
