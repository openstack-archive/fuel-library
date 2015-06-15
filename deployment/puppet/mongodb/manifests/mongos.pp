# This installs a Mongo Shard daemon. See README.md for more details.
class mongodb::mongos (
  $ensure           = $mongodb::params::mongos_ensure,
  $config           = $mongodb::params::mongos_config,
  $config_content   = $mongodb::params::mongos_config_content,
  $configdb         = $mongodb::params::mongos_configdb,
  $service_provider = $mongodb::params::mongos_service_provider,
  $service_name     = $mongodb::params::mongos_service_name,
  $service_enable   = $mongodb::params::mongos_service_enable,
  $service_ensure   = $mongodb::params::mongos_service_ensure,
  $service_status   = $mongodb::params::mongos_service_status,
  $package_ensure   = $mongodb::params::package_ensure_mongos,
  $package_name     = $mongodb::params::mongos_package_name,
) inherits mongodb::params {

  if ($ensure == 'present' or $ensure == true) {
    anchor { 'mongodb::mongos::start': }->
    class { 'mongodb::mongos::install': }->
    class { 'mongodb::mongos::config': }->
    class { 'mongodb::mongos::service': }->
    anchor { 'mongodb::mongos::end': }
  } else {
    anchor { 'mongodb::mongos::start': }->
    class { 'mongodb::mongos::service': }->
    class { 'mongodb::mongos::config': }->
    class { 'mongodb::mongos::install': }->
    anchor { 'mongodb::mongos::end': }
  }

}
