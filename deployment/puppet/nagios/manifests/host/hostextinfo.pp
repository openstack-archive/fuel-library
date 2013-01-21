define nagios::host::hostextinfo() {
  $distro = inline_template("<%= scope.lookupvar('::lsbdistid').downcase -%>")

  @@nagios_hostextinfo { $name:
    ensure          => present,
    notes           => $::lsbdistid,
    icon_image      => "base/${distro}.png",
    icon_image_alt  => $::lsbdistid,
    statusmap_image => "base/${distro}.gd2",
    vrml_image      => "${distro}.png",
    target          => "/etc/nagios3/conf.d/${::hostname}_hostextinfo.cfg",
  }
}