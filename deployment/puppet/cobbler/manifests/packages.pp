#    Copyright 2013 Mirantis, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


class cobbler::packages {

  case $operatingsystem {
    /(?i)(centos|redhat)/:  {
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["xinetd", "tftp-server", "syslinux", "wget", "python-ipaddr"]
      $django_package = "python-django"
    }
    /(?i)(debian|ubuntu)/:  {
    #FIXME(bogdando) ensure no fixed versions, if updating/downgrading cobbler/django as well
      $cobbler_package = "cobbler"
      $cobbler_web_package = "cobbler-web"
      $dnsmasq_package = "dnsmasq"
      $cobbler_additional_packages = ["tftpd-hpa", "syslinux", "wget", "python-ipaddr"]
      $django_package = "python-django"
      $django_version = "1.3.1-4ubuntu1"
    }
  }

  define cobbler_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  cobbler_safe_package { $cobbler_additional_packages : }

  package { $django_package :
        ensure => present
  }

  package { $cobbler_package :
    require => [
                Package[$dnsmasq_package],
                Package[$cobbler_additional_packages],
                Package[$django_package],
                ],
  }

  package { $cobbler_web_package :
    require => Package[$cobbler_package]
  }

  package { $dnsmasq_package:
    ensure => installed
  }

  Package<||>

}
