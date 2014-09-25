#
# Configure the Mech Driver for cisco neutron plugin
# More info available here:
# https://wiki.openstack.org/wiki/Neutron/ML2/MechCiscoNexus
#
# === Parameters
#
# [*neutron_config*]
# Neutron switch configuration for ml2_cisco_conf.ini
# Example nexus config format:
#  { 'switch_hostname' => {'username' => 'admin',
#    'ssh_port' => 22,
#    'password' => "password",
#    'ip_address' => "172.18.117.28",
#    'servers' => {
#      'control01' => "portchannel:20",
#      'control02' => "portchannel:10"
#    }}}
#

class neutron::plugins::ml2::cisco::nexus (
  $nexus_config = undef,
)
{

  if !$nexus_config {
    fail('No nexus config specified')
  }

  # For Ubuntu: This package is not available upstream
  # Please use the source from:
  # https://launchpad.net/~cisco-openstack/+archive/python-ncclient
  # and install it manually
  package { 'python-ncclient':
    ensure => installed,
  } ~> Service['neutron-server']

  Neutron_plugin_ml2<||> ->
  file { $::neutron::params::cisco_ml2_config_file:
    owner   => 'root',
    group   => 'root',
    content => template('neutron/ml2_conf_cisco.ini.erb'),
  } ~> Service['neutron-server']

  create_resources(neutron::plugins::ml2::cisco::nexus_creds, $nexus_config)

}

