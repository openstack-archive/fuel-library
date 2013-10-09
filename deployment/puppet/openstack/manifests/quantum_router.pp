#This class installs quantum WITHOUT quantum api server which is installed on controller nodes
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.

class openstack::quantum_router (
  $verbose                  = 'False',
  $debug                    = 'False',
  $enabled                  = true,
  $quantum                  = true,
  $quantum_config           = {},
  $quantum_network_node     = false,
  $quantum_server           = true,
  $use_syslog               = false,
  $syslog_log_facility      = 'LOCAL4',
  $syslog_log_level         = 'WARNING',
  $ha_mode                  = false,
  $service_provider         = 'generic',
  #$internal_address         = $::ipaddress_br_mgmt,
  # $public_interface         = "br-ex",
  # $private_interface        = "br-mgmt",
  # $create_networks          = true,
) {
    class { '::quantum':
      quantum_config       => $quantum_config,
      verbose              => $verbose,
      debug                => $debug,
      use_syslog           => $use_syslog,
      syslog_log_facility  => $syslog_log_facility,
      syslog_log_level     => $syslog_log_level,
      server_ha_mode       => $ha_mode,
    }
    #todo: add quantum::server here (into IF)
    class { 'quantum::plugins::ovs':
      quantum_config      => $quantum_config,
      #bridge_mappings     => ["physnet1:br-ex","physnet2:br-prv"],
    }

    if $quantum_network_node {
      class { 'quantum::agents::ovs':
        #bridge_uplinks   => ["br-prv:${private_interface}"],
        #bridge_mappings  => ['physnet2:br-prv'],
        #verbose          => $verbose,
        #debug            => $debug,
        service_provider => $service_provider,
        quantum_config   => $quantum_config,      }
      # Quantum metadata agent starts only under pacemaker
      # and co-located with l3-agent
      class {'quantum::agents::metadata':
        verbose          => $verbose,
        debug            => $debug,
        service_provider => $service_provider,
        quantum_config   => $quantum_config,
        #metadata_ip      => $nova_api_vip,
      }
      class { 'quantum::agents::dhcp':
        quantum_config   => $quantum_config,
        verbose          => $verbose,
        debug            => $debug,
        service_provider => $service_provider,
      }
      class { 'quantum::agents::l3':
       #enabled             => $quantum_l3_enable,
        quantum_config   => $quantum_config,
        verbose             => $verbose,
        debug               => $debug,
        service_provider    => $service_provider,
        #create_networks     => $create_networks,
        #segment_range       => $segment_range,
      }
    }

    if !defined(Sysctl::Value['net.ipv4.ip_forward']) {
      sysctl::value { 'net.ipv4.ip_forward': value => '1'}
    }

}
# vim: set ts=2 sw=2 et :