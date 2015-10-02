# Not a doc string

class cluster::neutron::dhcp (
  $plugin_config    = '/etc/neutron/dhcp_agent.ini',
  $agents_per_net   = '2',      # Value, recommended by Neutron team.
) {

  require cluster::neutron
  include neutron::params

  if $::neutron::params::dhcp_agent_package {
    $package_name = $::neutron::params::dhcp_agent_package
  } else {
    $package_name = $::neutron::params::package_name
  }
  $service_name   = $::neutron::params::dhcp_agent_service

  $primitive_class      = 'ocf'
  $primitive_provider   = 'fuel'
  $primitive_type       = 'ocf-neutron-dhcp-agent'

  $complex_type         = 'clone'
  $complex_metadata     = {
    'interleave' => 'true',
  }

  $parameters  = {
    'plugin_config'                  => $plugin_config,
    'remove_artifacts_on_stop_start' => true,
  }

  $operations           = {
    'monitor' => {
      'interval' => '20',
      'timeout'  => '10',
    },
    'start'   => {
      'timeout' => '60',
    },
    'stop'    => {
      'timeout' => '60',
    }
  }

  Neutron_config <| name == 'DEFAULT/dhcp_agents_per_network' |> {
    value => $agents_per_net,
  }

  service { $service_name :
    ensure => 'running',
    enable => true,
  }

  pacemaker::service { $service_name :
    prefix             => true,
    primitive_type     => $primitive_type,
    primitive_class    => $primitive_class,
    primitive_provider => $primitive_provider,
    complex_type       => $complex_type,
    complex_metadata   => $complex_metadata,
    parameters         => $parameters,
    operations         => $operations,
  }

  tweaks::ubuntu_service_override { $service_name :
    package_name => $package_name,
    service_name => $service_name,
  }

}
