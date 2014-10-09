class swift::storage::account(
  $package_ensure = 'present'
) {
  swift::storage::generic { 'account':
    package_ensure => $package_ensure,
  }

  include swift::params

  service { 'swift-account-reaper':
    ensure    => running,
    name      => $::swift::params::account_reaper_service_name,
    enable    => true,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-account'],
  }

  service { 'swift-account-auditor':
    ensure    => running,
    name      => $::swift::params::account_auditor_service_name,
    enable    => true,
    provider  => $::swift::params::service_provider,
    require   => Package['swift-account'],
  }
}
