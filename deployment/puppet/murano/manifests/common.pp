class murano::common {

  include murano::params

  package { 'murano_common':
    ensure => installed,
    name   => $murano::params::common_package_name,
  }

}
