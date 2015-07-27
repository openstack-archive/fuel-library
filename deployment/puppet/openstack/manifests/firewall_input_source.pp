# == Class: openstack::firewall_input_source
#
# Configure accept INPUT rules for array of IPs
#
# === Parameters
#
# [*$service_name*]
# Short name of service this rule manages and prefix [000-999]
#
# [*$port*]
# Port number this rule manages
#
# [*$proto*]
# Optional. Protocol this rule works with. Default - tcp.
#
# [*$source*]
# Array of source CIDRs to ACCEPT.
#
# === Examples
#
#  openstack::firewall_input_source { ['1.1.1.1/24', '2.2.2.2/24']:
#    service_name => '118 libvirt',
#    port         => '11111',
#  }
#
# === Authors
#
# Mirantis
#
# === Copyright
#
# GNU GPL
#
define openstack::firewall_input_source ( $service_name,
                                          $port,
                                          $proto  = 'tcp',
                                          $source = $name ) {
  firewall { "${service_name}-${source}":
    port   => $port,
    proto  => $proto,
    action => 'accept',
    source => $source,
  }
}
