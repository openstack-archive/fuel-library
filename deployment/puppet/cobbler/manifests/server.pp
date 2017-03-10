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
#
# == Class: cobbler::server
#
# Installs cobbler package and service
#
# == Parameters:
#
# [*dhcp_lease_max*]
# (optional) Sets the maximum number of leases available in dnsmasq.
#
# [*lease_time*]
# (optional) Sets the default lease time for DHCP clients.

class cobbler::server (
  $production     = 'prod',
  $domain_name    = 'local',
  $dns_search     = 'local',
  $dns_domain     = 'local',
  $dns_upstream   = ['8.8.8.8'],
  $dhcp_gateway   = unset,
  $dhcp_lease_max = '1800',
  $dhcp_ipaddress = '127.0.0.1',
  $lease_time     = '120m',
  $server         = $ipaddress,
  $name_server    = $ipaddress,
  $next_server    = $ipaddress,
  $pxetimeout     = '0',
) {
  include ::cobbler::packages

  Exec {
    path => '/usr/bin:/bin:/usr/sbin:/sbin'
  }

  $real_fqdn = $::fqdn

  case $::operatingsystem {
    /(?i)(centos|redhat)/ : {
      $cobbler_service     = 'cobblerd'
      $cobbler_web_service = 'httpd'
      $dnsmasq_service     = 'dnsmasq'

      service { 'xinetd':
        ensure     => running,
        enable     => true,
        hasrestart => true,
        require    => Package[$cobbler::packages::cobbler_additional_packages],
      }

      file { '/etc/xinetd.conf':
        content => template('cobbler/xinetd.conf.erb'),
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        require => Package[$cobbler::packages::cobbler_additional_packages],
        notify  => Service['xinetd'],
      }

      File<| title == '/etc/httpd/conf.d/ssl.conf' |> {
        ensure => absent
      }

    }
    /(?i)(debian|ubuntu)/ : {
      $cobbler_service     = 'cobbler'
      $cobbler_web_service = 'apache2'
      $dnsmasq_service     = 'dnsmasq'
      $apache_ssl_module   = 'ssl'

    }
    default : {
      fail('Unsupported OS')
    }
  }
  File['/etc/cobbler/modules.conf'] -> File['/etc/cobbler/settings'] ->
  Service[$cobbler_service] ->
    Exec['cobbler_sync'] ->
      Service[$dnsmasq_service]

  service { $cobbler_service:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Package[$cobbler::packages::cobbler_package],
  }

  service { $dnsmasq_service:
    ensure     => running,
    enable     => true,
    hasrestart => true,
    require    => Package[$cobbler::packages::dnsmasq_package],
    subscribe  => Exec['cobbler_sync'],
  }

  if $apache_ssl_module {
    file { '/etc/apache2/sites-enabled/default-ssl':
      ensure => link,
      target => '/etc/apache2/sites-available/default-ssl',
      before => Service[$cobbler_web_service],
      notify => Service[$cobbler_web_service],
    }
  }

  #TODO(mattymo): refactor this into cobbler module and use OS-dependent
  #directories
  file { [
          '/var/lib/fuel',
          '/var/lib/fuel/keys',
          '/var/lib/fuel/keys/master',
          '/var/lib/fuel/keys/master/cobbler',
          ]:
    ensure => 'directory',
  }
  openssl::certificate::x509 { 'cobbler':
    ensure       => present,
    country      => 'US',
    organization => 'Fuel',
    commonname   => $real_fqdn,
    state        => 'California',
    unit         => 'Fuel Deployment Team',
    email        => "root@${dns_domain}",
    days         => 3650,
    base_dir     => '/var/lib/fuel/keys/master/cobbler/',
    owner        => 'root',
    group        => 'root',
    force        => false,
    cnf_tpl      => 'openssl/cert.cnf.erb',
    require      => File['/var/lib/fuel/keys/master/cobbler'],
    notify       => Service[$cobbler_web_service],
  }

  file_line { 'Change debug level in cobbler':
    require => Package[$cobbler::packages::cobbler_web_package],
    before  => Service[$cobbler_web_service],
    ensure  => present,
    path    => '/usr/share/cobbler/web/settings.py',
    line    => 'DEBUG = False',
    match   => '^DEBUG.*$',
  }

  class { 'cobbler::apache':
  }

  exec { 'wait_for_web_service':
    command   => '[ $(curl --connect-timeout 1 -s -w %{http_code} http://127.0.0.1:80/ -o /dev/null) -lt 500 ]',
    require   => Service[$cobbler_web_service],
    subscribe => Service[$cobbler_web_service],
    tries     => 60,
    try_sleep => 1,
  }

  exec { 'cobbler_sync':
    command     => 'cobbler sync',
    refreshonly => false,
    require     => [
      Service[$cobbler_web_service],
      Exec['wait_for_web_service'],
      Package[$cobbler::packages::cobbler_package],
      Package[$cobbler::packages::dnsmasq_package],
      File['/etc/dnsmasq.upstream']],
    subscribe   => Service[$cobbler_service],
    notify      => [Service[$dnsmasq_service], Service['xinetd']],
    tries       => 20,
    try_sleep   => 3,
  }

  file { '/etc/cobbler/modules.conf':
    content => template('cobbler/modules.conf.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Package[$cobbler::packages::cobbler_package]],
    notify  => [Service[$cobbler_service], Exec['cobbler_sync']],
  }

  file { '/etc/cobbler/settings':
    content => template('cobbler/settings.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$cobbler::packages::cobbler_package],
    notify  => [Service[$cobbler_service], Exec['cobbler_sync']],
  }

  file { '/etc/cobbler/dnsmasq.template':
    content => template('cobbler/dnsmasq.template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [
      Package[$cobbler::packages::cobbler_package],
      Package[$cobbler::packages::dnsmasq_package]],
    notify  => [
      Service[$cobbler_service],
      Exec['cobbler_sync'],
      Service[$dnsmasq_service],],
  }

  file { '/etc/cobbler/pxe/pxedefault.template':
    content => template('cobbler/pxedefault.template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$cobbler::packages::cobbler_package],
    notify  => [Service[$cobbler_service], Exec['cobbler_sync']],
  }

  file { '/etc/cobbler/pxe/pxelocal.template':
    content => template('cobbler/pxelocal.template.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$cobbler::packages::cobbler_package],
    notify  => [Service[$cobbler_service], Exec['cobbler_sync']],
  }

  exec { '/var/lib/tftpboot/chain.c32':
    command => 'cp /usr/share/syslinux/chain.c32 /var/lib/tftpboot/chain.c32',
    unless  => 'test -e /var/lib/tftpboot/chain.c32',
    require => [
      Package[$cobbler::packages::cobbler_additional_packages],
      Package[$cobbler::packages::cobbler_package],]
  }

  file { '/etc/dnsmasq.upstream':
    content => template('cobbler/dnsmasq.upstream.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }
}
