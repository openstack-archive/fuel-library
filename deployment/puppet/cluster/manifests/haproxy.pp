# == Define: cluster::haproxy
#
# Configure HaProxy, started under corosync/pacemaker
#
# === Parameters
#
# [*name*]
#   xxxxxxxxxxx
#
class cluster::haproxy (
  $global_options   = $haproxy::params::global_options,
  $defaults_options = $haproxy::params::defaults_options
) inherits ::haproxy::params {
  include concat::setup

  $cib_name = "p_haproxy"

  cs_shadow { $cib_name: cib => $cib_name }

  if $primary_controller {
  cs_commit { $cib_name: cib => $cib_name } ~> ::Corosync::Cleanup["$cib_name"]
  ::corosync::cleanup { $cib_name: }
  Cs_commit[$cib_name] -> ::Corosync::Cleanup[$cib_name]
  Cs_commit[$cib_name] ~> ::Corosync::Cleanup[$cib_name]

  } else {
  cs_commit { $cib_name: cib => $cib_name } ~> ::Corosync::Clonecleanup["$cib_name"]
  ::corosync::clonecleanup { $cib_name: }
  Cs_commit[$cib_name] -> ::Corosync::Clonecleanup[$cib_name]
  Cs_commit[$cib_name] ~> ::Corosync::Clonecleanup[$cib_name]

  }



  file {'haproxy-ocf':
    path=>'/usr/lib/ocf/resource.d/pacemaker/haproxy', 
    mode => 755,
    owner => root,
    group => root,
    source => "puppet:///modules/cluster/haproxy",
  } ->
  cs_resource { $cib_name:
    ensure          => present,
    cib             => $cib_name,
    primitive_class => 'ocf',
    provided_by     => 'pacemaker',
    primitive_type  => 'haproxy',
    multistate_hash => {
      'type' => 'clone',
    },
    ms_metadata => {
      'interleave' => 'true',
    },
    parameters => {
      # 'nic'     => $vip[nic],
      # 'ip'      => $vip[ip],
    },
    operations => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '30'
      },
      'start' => {
        'timeout' => '30'
      },
      'stop' => {
        'timeout' => '30'
      },
    },
  }

  if ($::osfamily == 'Debian') {
    Package['haproxy'] ->
        file { '/etc/default/haproxy': content => 'ENABLED=0' } ->
          Service['haproxy']
  }
  if ($::osfamily == 'RedHat') {
  Package['pacemaker'] -> 
  package { 'haproxy':
    ensure  => true,
    name    => 'haproxy',
  } ->
  file { $global_options['chroot']: 
    ensure => directory 
  } 
  if $::operatingsystem == 'Ubuntu' {
      file { "/etc/init/haproxy.override":
      replace => "no",
      ensure  => "present",
      content => "manual",
      mode    => 644,
      }
  }
  service { 'haproxy-init-stopped':
    enable     => false,
    ensure     => stopped,
    hasrestart => true,
    hasstatus  => true,
  } ->
  sysctl::value { 'net.ipv4.ip_nonlocal_bind': 
    value => '1' 
  } ->
  service { 'haproxy':
    name       => "p_haproxy",
    enable     => $enabled,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    provider   => "pacemaker",
  }
  } else {
  Package['pacemaker'] ->
  package { 'haproxy':
    ensure  => true,
    name    => 'haproxy',
  } ->
  file { $global_options['chroot']:
    ensure => directory
  } ->
  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value => '1'
  } ->
  service { 'haproxy':
    name       => "p_haproxy",
    enable     => $enabled,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    provider   => "pacemaker",
  }
  }
}

#Class['corosync'] -> Class['cluster::haproxy']
if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Class['cluster::haproxy']
}
#
###
