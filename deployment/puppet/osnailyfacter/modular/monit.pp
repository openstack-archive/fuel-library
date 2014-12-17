if $role == 'compute' {
# Configure monit watchdogs
# FIXME(bogdando) replace service_path and action to systemd, once supported
  if $use_monit {
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
}

if $role == 'controller' {
  if $::use_monit {
  # Configure service names for monit watchdogs and 'service' system path
  # FIXME(bogdando) replace service_path to systemd, once supported
    include nova::params
    include cinder::params
    include neutron::params
    include l23network::params
    $nova_compute_name   = $::nova::params::compute_service_name
    $nova_api_name       = $::nova::params::api_service_name
    $nova_network_name   = $::nova::params::network_service_name
    $cinder_volume_name  = $::cinder::params::volume_service
    $ovs_vswitchd_name   = $::l23network::params::ovs_service_name
    case $::osfamily {
      'RedHat' : {
        $service_path   = '/sbin/service'
      }
      'Debian' : {
        $service_path    = '/usr/sbin/service'
      }
      default  : {
        fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
      }
    }
  }
}
