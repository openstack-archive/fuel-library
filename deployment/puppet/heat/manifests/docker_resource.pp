# Installs & configure the heat docker resource
#
class heat::docker_resource (
    $enabled      = true,
    $package_name = $heat::params::docker_resource_package_name,
    ) inherits heat::params {

        if $enabled {
            package { 'heat-docker':
            ensure => installed,
            name   => $package_name,
        }

        Package['heat-docker'] ~> Service<| title == 'heat-engine' |>
    }
}
