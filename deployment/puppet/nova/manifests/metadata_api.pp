#
class nova::metadata_api (
  $enabled        = true,
  $ensure_package = present
) {

  include nova::params

  nova::generic_service { 'metadata-api':
     enabled        => true,
     package_name   => "$::nova::params::meta_api_package_name",
     service_name   => "$::nova::params::meta_api_service_name",
  }

  Package["$::nova::params::meta_api_package_name"] -> 
    Nova_config<||> ~> 
      Service["$::nova::params::meta_api_service_name"]

}
