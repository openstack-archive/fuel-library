# == Class: nova::rabbitmq_pacemaker
#
# Overrides rabbitmq service provider for nova as a pacemaker
#
# TODO(bogdando) that one just an example of Pacemaker service
#   provider wrapper implementation and should be moved to openstack_extra
#   and params should be described
#

class nova::rabbitmq_pacemaker (
  $primary_controller = 'true',
  $service_name       = $::rabbitmq::service_name,
  $service_ensure     = $::rabbitmq::service_ensure,
  $service_manage     = $::rabbitmq::service_manage,
  $service_provider   = $::rabbitmq::service_provider,
  $port               = $::rabbitmq::port,
  $debug              = false,
  $ocf_source         = 'puppet:///modules/openstack/ocf/rabbitmq',
  $ocf_path           = '/usr/lib/ocf/resource.d/mirantis/rabbitmq-server',
) inherits ::rabbitmq::service {

  if $service_provider == 'pacemaker' {
    validate_re($service_ensure, '^(running|stopped)$')
    validate_bool($service_manage)

    if ($service_manage) {
      if $service_ensure == 'running' {
        $ensure_real = 'running'
        $enable_real = true
      } else {
        $ensure_real = 'stopped'
        $enable_real = false
      }

      $service_name_pcs = "p_${service_name}"

      # Override and configure service under pacemaker
      # NOTE(bogdando) pacemaker service provider type should as well disable
      #   OS-aware services in its ruby code
      # NOTE(bogdando) requires service provider type for pacemaker in catalog

      Service[$service_name] {
        name       => $service_name_pcs,
        ensure     => $ensure_real,
        enable     => $enable_real,
        provider   => 'pacemaker',
        hasstatus  => true,
        hasrestart => true,
      }

      file {'rabbitmq-ocf':
        path   => $ocf_path,
        mode   => '0755',
        owner  => root,
        group  => root,
        source => $ocf_source,
      }

      # TODO(bogdando) put hardcode as a class params
      if ($primary_controller) {
        cs_resource {$service_name_pcs:
          ensure          => present,
          primitive_class => 'ocf',
          provided_by     => 'mirantis',
          primitive_type  => 'rabbitmq-server',
          parameters      => {
            'node_port'     => $port,
            'debug'         => $debug,
          },
          metadata                 => {
             'migration-threshold' => 'INFINITY',
             'failure-timeout'     => '60s'

          },
          multistate_hash => {
            'type' => 'master',
          },
          ms_metadata => {
            'notify'      => 'true',
            # We shouldn't enable ordered start for parallel start of RA.
            'ordered'     => 'false',
            'interleave'  => 'true',
            'master-max'  => '1',
            'master-node-max' => '1',
            'target-role' => 'Master'
          },
          operations => {
            'monitor' => {
              'interval' => '30',
              'timeout'  => '60'
            },
            'monitor:Master' => { # name:role
              'role' => 'Master',
              # should be non-intercectable with interval from ordinary monitor
              'interval' => '27',
              'timeout'  => '60'
            },
            'start' => {
              'timeout' => '120'
            },
            'stop' => {
              'timeout' => '60'
            },
            'promote' => {
              'timeout' => '120'
            },
            'demote' => {
              'timeout' => '60'
            },
            'notify' => {
              'timeout' => '60'
            },
          },
        }
        File['rabbitmq-ocf'] -> Cs_resource[$service_name_pcs] -> Service[$service_name]
      }
      File<| title == 'ocf-mirantis-path' |> -> File['rabbitmq-ocf']
      Package['pacemaker'] -> File<| title == 'ocf-mirantis-path' |>
      Package['pacemaker'] -> File['rabbitmq-ocf']
      File['rabbitmq-ocf'] -> Service[$service_name]
      Service[$service_name] -> Rabbitmq_user <||>
    }
  }
}
