class murano::metadataclient {

  include murano::params

  package { 'murano_metadataclient':
    ensure => installed,
    name   => $::murano::params::murano_metadataclient_package_name,
  }

}
