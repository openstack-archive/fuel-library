class murano::metadataclient {

  include murano::params

  package { 'murano_metadataclient':
    ensure => installed,
    name   => $murano::params::metadataclient_package_name,
  }

}
