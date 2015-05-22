# == Class: cluster::haproxy_ocf
#
# Configure OCF service for HAProxy managed by corosync/pacemaker
#
class cluster::haproxy_ocf (
  $primary_controller,
  $debug = false,
  $other_networks = false,
){
  anchor {'haproxy': }

  $service_name = 'p_haproxy'

  #file {'haproxy-ocf':
  #  path   =>'/usr/lib/ocf/resource.d/fuel/ns_haproxy',
  #  mode   => '0755',
  #  owner  => root,
  #   group  => root,
  #   source => 'puppet:///modules/cluster/ocf/ns_haproxy',
  #  }
  #Anchor['haproxy'] -> File['haproxy-ocf']
  #File<| title == 'ocf-fuel-path' |> -> File['haproxy-ocf']

  if $primary_controller {
    cs_resource { $service_name:
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ns_haproxy',
      complex_type    => 'clone',
      ms_metadata     => {
        'interleave' => true,
      },
      metadata        => {
        'migration-threshold' => '3',
        'failure-timeout'     => '120',
      },
      parameters      => {
        'ns'             => 'haproxy',
        'debug'          => $debug,
        'other_networks' => "'$other_networks'",
      },
      operations      => {
        'monitor' => {
          'interval' => '30',
          'timeout'  => '60'
        },
        'start'   => {
          'timeout' => '30'
        },
        'stop'    => {
          'timeout' => '60'
        },
      },
    }

    cs_rsc_colocation { 'haproxy-with-vip_public':
      ensure     => present,
      score      => 'INFINITY',
      primitives => [
          "clone_${service_name}",
          "vip__public"
      ],
    }
    cs_rsc_colocation { 'haproxy-with-vip_management':
      ensure     => present,
      score      => 'INFINITY',
      primitives => [
          "clone_${service_name}",
          "vip__management"
      ],
    }

    #    File['haproxy-ocf'] -> Cs_resource[$service_name]
    Cs_resource[$service_name] -> Cs_rsc_colocation['haproxy-with-vip_public'] -> Service[$service_name]
    Cs_resource[$service_name] -> Cs_rsc_colocation['haproxy-with-vip_management'] -> Service[$service_name]
    #} else {
    # File['haproxy-ocf'] -> Service[$service_name]
  }

  if ($::osfamily == 'Debian') {
    file { '/etc/default/haproxy':
      content => 'ENABLED=0',
    } -> Service <| title == $service_name |>
    if $::operatingsystem == 'Ubuntu' {
      file { '/etc/init/haproxy.override':
        ensure  => 'present',
        replace => 'no',
        content => 'manual',
        mode    => '0644'
      } -> Service <| title == $service_name |>
    }
  }

  service { 'haproxy-init-stopped':
    ensure     => 'stopped',
    name       => 'haproxy',
    enable     => false,
  } Service <| title == $service_name |>


  sysctl::value { 'net.ipv4.ip_nonlocal_bind':
    value => '1'
  } ->
  service { $service_name:
    ensure     => 'running',
    name       => $service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    provider   => 'pacemaker',
  } -> Anchor['haproxy-done']

  anchor {'haproxy-done': }
}
