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
  cs_commit { $cib_name: cib => $cib_name }
  ::corosync::cleanup { $cib_name: }

  Cs_commit[$cib_name] -> ::Corosync::Cleanup[$cib_name]
  Cs_commit[$cib_name] ~> ::Corosync::Cleanup[$cib_name]


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
      Service['haproxy-init-stopped'] ->
        file { '/etc/default/haproxy': content => 'ENABLED=0' } ->
          Service['haproxy']
  }

  Package['pacemaker'] -> 
  package { 'haproxy':
    ensure  => true,
    name    => 'haproxy',
  } ->
  file { $global_options['chroot']: 
    ensure => directory 
  } ->
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

}

#Class['corosync'] -> Class['cluster::haproxy']
if defined(Corosync::Service['pacemaker']) {
  Corosync::Service['pacemaker'] -> Class['cluster::haproxy']
}
#
###