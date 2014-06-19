# == Class: cluster::haproxy_ocf
#
# Configure OCF service for HAProxy managed by corosync/pacemaker
#
class cluster::haproxy_ocf (
  $primary_controller
){
  anchor {'haproxy': }

  $service_name = 'p_haproxy'

  file {'haproxy-ocf':
    path   =>'/usr/lib/ocf/resource.d/mirantis/ns_haproxy',
    mode   => '0755',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/cluster/ns_haproxy',
  }
  Anchor['haproxy'] -> File['haproxy-ocf']
  File<| title == 'ocf-mirantis-path' |> -> File['haproxy-ocf']

  if $primary_controller {
    cs_resource { $service_name:
      ensure          => present,
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

    cs_colocation { 'vip_public-with-haproxy':
      ensure     => present,
      score      => 'INFINITY',
      primitives => [
          "vip__public_old",
          "clone_${service_name}"
      ],
    }
    cs_colocation { 'vip_management-with-haproxy':
      ensure     => present,
      score      => 'INFINITY',
      primitives => [
          "vip__management_old",
          "clone_${service_name}"
      ],
    }

    File['haproxy-ocf'] -> Cs_resource[$service_name]
    Cs_resource[$service_name] -> Cs_colocation['vip_public-with-haproxy'] -> Service[$service_name]
    Cs_resource[$service_name] -> Cs_colocation['vip_management-with-haproxy'] -> Service[$service_name]
  } else {
    File['haproxy-ocf'] -> Service[$service_name]
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
  }

  service { 'haproxy-init-stopped':
    name       => 'haproxy',
    enable     => false,
    ensure     => 'stopped',
  } -> File['haproxy-ocf']

  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value => '1'
  } ->
  service { "$service_name":
    name       => $service_name,
    enable     => true,
    ensure     => 'running',
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  } -> Anchor['haproxy-done']

  anchor {'haproxy-done': }
}
