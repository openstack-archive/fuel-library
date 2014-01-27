# This installs a MongoDB client (CLI).
class mongodb::client (
  $ensure           = $mongodb::params::client_ensure,
  $package_name     = $mongodb::params::client_package_name,

) inherits mongodb::params {

  package { 'mongodb_client':
    ensure => $ensure,
    name   => $package_name,
  }
}
