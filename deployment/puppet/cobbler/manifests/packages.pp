class cobbler::packages {

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["xinetd", "tftp-server", "syslinux", "wget"]
      $django_package = "Django"
      $django_version = "1.3.4-1.el6"
    }
    /(?i)(debian|ubuntu)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["tftpd-hpa", "syslinux", "wget", "python-ipaddr"]
      $django_package = "python-django"
      $django_version = "1.3.1-4ubuntu1.4"
    }
  }

  define cobbler_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  cobbler_safe_package { $cobbler_additional_packages : }

  package { $django_package :
        ensure => $django_version
  }

  package { $cobbler_package :
    ensure => installed,
    require => [
                Package[$dnsmasq_package],
                Package[$cobbler_additional_packages],
                Package[$django_package],
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
