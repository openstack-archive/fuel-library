# This installs a MongoDB client (CLI).
class mongodb::client (
  $ensure           = $mongodb::params::client_ensure,
  $package_name     = $mongodb::params::client_package_name,

) inherits mongodb::params {


  if ($ensure == 'present' or $ensure == true) {
    class { 'mongodb::client::install': }
  } else {
    class { 'mongodb::client::install': }
  }
}
