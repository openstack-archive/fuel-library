#This class installs neutron WITHOUT neutron api server which is installed on controller nodes
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.

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
  $syslog_log_level         = 'WARNING',
  $ha_mode                  = false,
  $service_provider         = 'generic',
  #$internal_address         = $::ipaddress_br_mgmt,
  # $public_interface         = "br-ex",
  # $private_interface        = "br-mgmt",
  # $create_networks          = true,
) {
    class { '::neutron':
      neutron_config       => $neutron_config,
      verbose              => $verbose,
      debug                => $debug,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility,
      syslog_log_level     => $syslog_log_level,
      server_ha_mode       => $ha_mode,
    }
    #todo: add neutron::server here (into IF)
    class { '::neutron::plugins::ovs':
      neutron_config      => $neutron_config,
      #bridge_mappings     => ["physnet1:br-ex","physnet2:br-prv"],
    }

    if $neutron_network_node {
      class { '::neutron::agents::ovs':
        service_provider => $service_provider,
        neutron_config   => $neutron_config,      }
      # neutron metadata agent starts only under pacemaker
      # and co-located with l3-agent
      class {'::neutron::agents::metadata':
        verbose          => $verbose,
        debug            => $debug,
        service_provider => $service_provider,
        neutron_config   => $neutron_config,
      }
      class { '::neutron::agents::dhcp':
        neutron_config   => $neutron_config,
        verbose          => $verbose,
        debug            => $debug,
        service_provider => $service_provider,
      }
      class { '::neutron::agents::l3':
        neutron_config   => $neutron_config,
        verbose          => $verbose,
        debug            => $debug,
        service_provider => $service_provider,

      }
    }

    if !defined(Sysctl::Value['net.ipv4.ip_forward']) {
      sysctl::value { 'net.ipv4.ip_forward': value => '1'}
    }

}
