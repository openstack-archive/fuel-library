class murano::common {

  include murano::params

  package { 'murano_common':
    ensure => installed,
    name   => $::murano::params::murano_common_package_name,
  }

}
