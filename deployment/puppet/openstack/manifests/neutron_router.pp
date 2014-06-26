#This class installs neutron WITHOUT neutron api server which is installed on controller nodes
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead

class openstack::neutron_router (
  $verbose                  = false,
  $debug                    = false,
  $enabled                  = true,
  $neutron                  = true,
  $neutron_config           = {},
  $neutron_network_node     = false,
  $neutron_server           = true,
  $use_syslog               = false,
  $syslog_log_facility      = 'LOG_LOCAL4',
  $ha_mode                  = false,
  $primary_controller       = false,
  $service_provider         = 'generic'
) {
    class { '::neutron':
      neutron_config       => $neutron_config,
      verbose              => $verbose,
      debug                => $debug,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility,
      server_ha_mode       => $ha_mode
    }

    if $neutron_config[L2][provider] == 'ml2' {
      class { '::neutron::plugins::ml2_plugin':
        neutron_config      => $neutron_config,
      }
    } else {
      class { '::neutron::plugins::ovs':
        neutron_config      => $neutron_config,
      }
    }

    if $neutron_network_node {
      if $neutron_config[L2][provider] == 'ml2' {
        class { '::neutron::agents::ml2_agent':
          neutron_config     => $neutron_config,
          primary_controller => $primary_controller,
          controller         => true,
          ha_mode            => $ha_mode
        }
      } else {
        class { '::neutron::agents::ovs':
          service_provider   => $service_provider,
          neutron_config     => $neutron_config,
          primary_controller => $primary_controller
        }
      }
      # neutron metadata agent starts only under pacemaker
      # and co-located with l3-agent
      class {'::neutron::agents::metadata':
        verbose            => $verbose,
        debug              => $debug,
        service_provider   => $service_provider,
        neutron_config     => $neutron_config,
        primary_controller => $primary_controller
      }
      class { '::neutron::agents::dhcp':
        neutron_config     => $neutron_config,
        verbose            => $verbose,
        debug              => $debug,
        service_provider   => $service_provider,
        primary_controller => $primary_controller
      }
      class { '::neutron::agents::l3':
        neutron_config     => $neutron_config,
        verbose            => $verbose,
        debug              => $debug,
        service_provider   => $service_provider,
        primary_controller => $primary_controller
      }
    }

    if !defined(Sysctl::Value['net.ipv4.ip_forward']) {
      sysctl::value { 'net.ipv4.ip_forward': value => '1'}
    }

}
