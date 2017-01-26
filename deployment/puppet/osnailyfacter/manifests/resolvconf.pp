# == Class: osnailyfacter::resolvconf
#
# Configure resolv.conf on fuel nodes
#
# === Parameters
#
# [*$management_vip*]
# Management virtual ip address
#
# === Examples
#
#  class { osnailyfacter::resolvconf:
#    management_vip => '1.1.1.1',
#  }
#
# === Authors
#
# Mirantis
#
# === Copyright
#
#    Copyright 2016 Mirantis, Inc.
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
#
class osnailyfacter::resolvconf (
  $management_vip
) {
  $file_path = $::osfamily ? {
    /(RedHat|CentOS)/ => '/etc/resolv.conf',
    /(Debian|Ubuntu)/ => '/etc/resolvconf/resolv.conf.d/head',
    default           => '/etc/resolv.conf',
  }

  file { $file_path:
    ensure  => file,
    content => template('osnailyfacter/resolv.conf.erb')
  }

  if $::osfamily =~ /(Debian|Ubuntu)/ {
    package { 'resolvconf':
      ensure => present,
    } ->
    file { '/etc/resolv.conf':
      ensure => link,
      target => '/run/resolvconf/resolv.conf',
    } ~>
    exec { 'dpkg-reconfigure resolvconf':
      command     => '/usr/sbin/dpkg-reconfigure -f noninteractive resolvconf',
      refreshonly => true,
    }
    file {'/etc/default/resolvconf':
      content => 'REPORT_ABSENT_SYMLINK="yes"',
    }
    service { 'resolvconf':
      ensure    => running,
      enable    => true,
      subscribe => [ File[$file_path], File['/etc/default/resolvconf'], ]
    }
  }
}
