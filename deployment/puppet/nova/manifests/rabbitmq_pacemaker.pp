# == Class: nova::rabbitmq_pacemaker
#
# Overrides rabbitmq service provider for nova as a pacemaker
# TODO(bogdando) that one just an example of Pacemaker service
#   provider wrapper implementation and should be moved to openstack_extras

class nova::rabbitmq_pacemaker (
  $primary_controller = 'true',
  $service_name       = $rabbitmq::service_name,
  $service_provider   = $rabbitmq::service_provider,
  $port               = $rabbitmq::port,
  $debug              = false,
  $ocf_source         = 'puppet:///modules/openstack/ocf/rabbitmq',
  $ocf_path           = '/usr/lib/ocf/resource.d/mirantis/rabbitmq-server',
) inherits rabbitmq::service {

  if $service_provider == 'pacemaker' {
    Service['rabbitmq-server'] {
      ensure => 'stopped',
      enable => 'false',
    }

    notify { 'Rabbitmq OS-aware service is stopped' :
      require => Service['rabbitmq-server'],
    }

    notify { 'Rabbitmq pacemaker resource is enabled' :
      require => Service[$service_name],
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
      cs_resource {$service_name:
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
      File['rabbitmq-ocf'] -> Cs_resource[$service_name] -> Service[$service_name]
    }
    File<| title == 'ocf-mirantis-path' |> -> File['rabbitmq-ocf']
    Package['pacemaker'] -> File<| title == 'ocf-mirantis-path' |>
    Package['pacemaker'] -> File['rabbitmq-ocf']
    Package['rabbitmq-server'] -> Service['rabbitmq-server']
    Package['rabbitmq-server'] -> File['rabbitmq-ocf'] ->
    Service[$service_name]
    Service[$service_name] -> Rabbitmq_user <||>
  }
}
