# Installs the ceilometer collector service
#
# == Params
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true.
#
#  [*manage_service*]
#    (optional)  Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*package_ensure*]
#    (optional) ensure state for package.
#    Defaults to 'present'
#
#  [*udp_address*]
#    (optional) the ceilometer collector udp bind address.
#    Set it empty to disable the collector listener.
#    Defaults to '0.0.0.0'
#
#  [*udp_port*]
#    (optional) the ceilometer collector udp bind port.
#    Defaults to '4952'
#
class ceilometer::collector (
  $manage_service = true,
  $enabled        = true,
  $package_ensure = 'present',
  $udp_address    = '0.0.0.0',
  $udp_port       = '4952',
) {

  include ::ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-collector']

  # We accept udp_address to be set to empty instead of the usual undef to stay
  # close to the "strange" upstream interface.
  if (is_ip_address($udp_address) != true and $udp_address != '' ){
    fail("${udp_address} is not a valid ip and is not empty")
  }

  ceilometer_config {
    'collector/udp_address' : value => $udp_address;
    'collector/udp_port'    : value => $udp_port;
  }

  Package[$::ceilometer::params::collector_package_name] -> Service['ceilometer-collector']
  ensure_resource( 'package', [$::ceilometer::params::collector_package_name],
    { ensure => $package_ensure }
  )

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
      Class['ceilometer::db'] -> Service['ceilometer-collector']
      Exec['ceilometer-dbsync'] ~> Service['ceilometer-collector']
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package['ceilometer-common'] -> Service['ceilometer-collector']
  service { 'ceilometer-collector':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::collector_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true
  }
}
