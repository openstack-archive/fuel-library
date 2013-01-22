define nagios::host::hostextinfo() {

  $distro = inline_template("<%= scope.lookupvar('::lsbdistid').downcase -%>")

  @@nagios_hostextinfo { $name:
    ensure          => present,
    host_name       => $::fqdn,
    notes           => $::lsbdistid,
    icon_image      => "base/${distro}.png",
    icon_image_alt  => $::lsbdistid,
    statusmap_image => "base/${distro}.gd2",
    vrml_image      => "${distro}.png",
    target          => "/etc/nagios3/${proj_name}/${::hostname}_hostextinfo.cfg",
  }
}
