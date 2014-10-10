# == Define: nova::generic_service
#
# This defined type implements basic nova services.
# It is introduced to attempt to consolidate
# common code.
#
# It also allows users to specify ad-hoc services
# as needed
#
# This define creates a service resource with title nova-${name} and
# conditionally creates a package resource with title nova-${name}
#
define nova::generic_service(
  $package_name,
  $service_name,
  $enabled            = false,
  $manage_service     = true,
  $ensure_package     = 'present',
  $ha_mode            = false,
  $primary_controller = false,
) {

  include nova::params

  $nova_title = "nova-${name}"
  # ensure that the service is only started after
  # all nova config entries have been set
  Exec['post-nova_config'] ~> Service<| title == $nova_title |>
  # ensure that the service has only been started
  # after the initial db sync
  Exec<| title == 'nova-db-sync' |> ~> Service<| title == $nova_title |>


  # I need to mark that ths package should be
  # installed before nova_config
  if ($package_name) {
    if !defined(Package[$package_name])
      { package { $nova_title: ensure => $ensure_package,
        name   => $package_name,
        notify => Service[$nova_title],
      }
    }
  }


  if $service_name {
    if $manage_service {
      if $enabled {
        $service_ensure = 'running'
      } else {
        $service_ensure = 'stopped'
      }
    }
    if $ha_mode {
      file { "${service_name}-ocf":
        path   => "/usr/lib/ocf/resource.d/mirantis/${service_name}",
        mode   => '0755',
        owner  => root,
        group  => root,
        source => "puppet:///modules/nova/ocf/${service_name}",
      }
      if $primary_controller {
        cs_resource { "p_${service_name}":
          ensure          => 'present',
          primitive_class => 'ocf',
          provided_by     => 'mirantis',
          primitive_type  => $service_name,
          multistate_hash => {
            'type' => 'clone',
          },
          operations => {
            'monitor' => {
               'interval' => '60',
               'timeout'  => '55',
            },
            'start' => {
              'timeout' => '60',
            },
            'stop' => {
              'timeout' => '60',
            },
          },
          require       => File["${service_name}-ocf"],
        }
        service { $nova_title:
          ensure  => $service_ensure,
          name    => $service_name,
          enable  => $enabled,
          provider => 'pacemaker',
          require   => [Package['nova-common'],
                        Package[$package_name],
                        Cs_resource["p_${service_name}"]],
        }
      }
    } else {
      service { $nova_title:
        ensure    => $service_ensure,
        name      => $service_name,
        enable    => $enabled,
        hasstatus  => true,
        hasrestart => true,
        require   => [Package['nova-common'], Package[$package_name]],
      }
    }
  }
}
