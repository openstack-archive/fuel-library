class swift::storage::object(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'object':
    package_ensure => $package_ensure
  }

  include swift::params

  service { 'swift-object-updater':
    ensure    => running,
    name      => $::swift::params::object_updater_service_name,
    enable    => true,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-object'],
  }

  service { 'swift-object-auditor':
    ensure    => running,
    name      => $::swift::params::object_auditor_service_name,
    enable    => true,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-object'],
  }
}
