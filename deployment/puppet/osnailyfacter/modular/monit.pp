$roles       = hiera($roles, [])
$use_monit   = hiera($use_monit, false)
$use_neutron = hiera($use_neutron, false)

# NOTE(bogdando) for controller nodes running Corosync with Pacemaker
#   we delegate all of the monitor functions to RA instead of monit.
if member($roles, 'controller') or member($roles, 'primary-controller') {
  $use_monit_real = false
} else {
  $use_monit_real = $use_monit
}

if $use_monit_real {
  # Configure service names for monit watchdogs and 'service' system path
  include nova::params
  include cinder::params
  include neutron::params
  include l23network::params
  $nova_compute_name   = $nova::params::compute_service_name
  $nova_api_name       = $nova::params::api_service_name
  $nova_network_name   = $nova::params::network_service_name
  $cinder_volume_name  = $cinder::params::volume_service
  $ovs_vswitchd_name   = $l23network::params::ovs_service_name
  # FIXME(bogdando) replace service_path to systemd, once supported
  case $::osfamily {
    'RedHat' : {
      $service_path   = '/sbin/service'
    }
    'Debian' : {
      $service_path    = '/usr/sbin/service'
    }
    default  : {
      fail("Unsupported osfamily: ${::osfamily} for os ${::operatingsystem}")
    }
  }

  # Configure monit watchdogs
  if $role == 'compute' {
    monit::process { $nova_compute_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/nova-compute',
      start_command => "${service_path} ${nova_compute_name} restart",
      stop_command  => "${service_path} ${nova_compute_name} stop",
      pidfile       => false,
    }
    if $use_neutron {
      monit::process { $ovs_vswitchd_name :
        ensure        => running,
        start_command => "${service_path} ${ovs_vswitchd_name} restart",
        stop_command  => "${service_path} ${ovs_vswitchd_name} stop",
        pidfile       => '/var/run/openvswitch/ovs-vswitchd.pid',
      }
    } else {
      monit::process { $nova_network_name :
        ensure        => running,
        matching      => '/usr/bin/python /usr/bin/nova-network',
        start_command => "${service_path} ${nova_network_name} restart",
        stop_command  => "${service_path} ${nova_network_name} stop",
        pidfile       => false,
      }
      monit::process { $nova_api_name :
        ensure        => running,
        matching      => '/usr/bin/python /usr/bin/nova-api',
        start_command => "${service_path} ${nova_api_name} restart",
        stop_command  => "${service_path} ${nova_api_name} stop",
        pidfile       => false,
      }
    }
  }

  if $role == 'cinder' {
    monit::process { $cinder_volume_name :
      ensure        => running,
      matching      => '/usr/bin/python /usr/bin/cinder-volume',
      start_command => "${service_path} ${cinder_volume_name} restart",
      stop_command  => "${service_path} ${cinder_volume_name} stop",
      pidfile       => false,
    }
  }

  # TODO(bogdando) add monit ceph-osd services monitoring, if required
  # TODO(bogdando) add monit zabbix services monitoring, if required
  # TODO(bogdando) add monit swift-storage services monitoring, if required.
  #   We don't deploy swift as a separate role for now, but will do, eventually
}
