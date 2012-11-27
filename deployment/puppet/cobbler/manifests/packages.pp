class cobbler::packages {

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["xinetd", "tftp-server", "syslinux", "wget"]
    }
    /(?i)(debian|ubuntu)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["tftpd-hpa", "syslinux", "wget", "python-ipaddr"]
    }
  }

  define cobbler_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  cobbler_safe_package { $cobbler_additional_packages : }

  package { $cobbler_package :
    ensure => installed,
    require => [
                Package[$dnsmasq_package],
                Package[$cobbler_additional_packages],
                ],
  }

  package { $cobbler_web_package :
    ensure => installed
  }

  package { $dnsmasq_package:
    ensure => installed
  }

  Package<||>

}
