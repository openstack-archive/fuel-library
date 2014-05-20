# == Class: cluster::haproxy_ocf
#
# Configure OCF service for HAProxy managed by corosync/pacemaker
#
class cluster::haproxy_ocf {
  anchor {'haproxy': }

  $cib_name = 'p_haproxy'

  cs_shadow { $cib_name: cib => $cib_name }
  cs_commit { $cib_name: cib => $cib_name }

  Anchor['haproxy'] -> Cs_shadow[$cib_name]

  Cs_commit[$cib_name] -> Service['haproxy']

  file {'haproxy-ocf':
    path   =>'/usr/lib/ocf/resource.d/mirantis/ns_haproxy',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ns_haproxy',
  }
  File<| title == 'ocf-mirantis-path' |> -> File['haproxy-ocf']
  File['haproxy-ocf'] -> Cs_resource[$cib_name]
  Cs_resource[$cib_name] -> Cs_colocation['vip_public-with-haproxy']
  Cs_resource[$cib_name] -> Cs_colocation['vip_management-with-haproxy']

  cs_colocation { 'vip_public-with-haproxy':
    ensure     => present,
    cib        => $cib_name,
    score      => 'INFINITY',
    primitives => [
        "vip__public_old",
        "clone_${cib_name}"
    ],
  }
  cs_colocation { 'vip_management-with-haproxy':
    ensure     => present,
    cib        => $cib_name,
    score      => 'INFINITY',
    primitives => [
        "vip__management_old",
        "clone_${cib_name}"
    ],
  }

  cs_resource { $cib_name:
    ensure          => present,
    cib             => $cib_name,
    primitive_class => 'ocf',
    provided_by     => 'mirantis',
    primitive_type  => 'ns_haproxy',
    multistate_hash => {
      'type' => 'clone',
    },
    ms_metadata => {
      'interleave' => 'true',
    },
    metadata => {
      'migration-threshold' => '3',
      'failure-timeout'     => '120',
    },
    parameters => {
      'ns' => 'haproxy',
    },
    operations => {
      'monitor' => {
        'interval' => '20',
        'timeout'  => '10'
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
    file { '/etc/default/haproxy':
      content => 'ENABLED=0',
    } -> File['haproxy-ocf']
    if $::operatingsystem == 'Ubuntu' {
      file { '/etc/init/haproxy.override':
        replace => 'no',
        ensure  => 'present',
        content => 'manual',
        mode    => '0644'
      } -> File['haproxy-ocf']
    }
  } elsif ($::osfamily == 'RedHat') {
    service { 'haproxy-init-stopped':
      enable     => false,
      ensure     => 'stopped',
      hasrestart => true,
      hasstatus  => true,
    } -> File['haproxy-ocf']
  }

  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value => '1'
  } ->
  File['haproxy-ocf'] ->
  service { 'haproxy':
    name       => $cib_name,
    enable     => true,
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  } -> Anchor['haproxy-done']

  anchor {'haproxy-done': }
}
