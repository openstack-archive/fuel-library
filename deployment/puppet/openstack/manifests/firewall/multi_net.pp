# Create firewall rules for multiple source networks
#
# Parameters
#
# [*action*]
# Action to be taken.
#
# [*chain*]
# iptables chain to use
#
# [*iniface*]
# Apply rule only to specified interface
#
# [*port*]
# Network port for the iptables rule.
#
# [*proto*]
# Network port for the iptables rule.
#
# [*rule_name*]
# Name to identify firewall rule.
# Example: '100 allow ssh'
#
# [*source_nets*]
# Array of networks from which to accept connections.
#

define openstack::firewall::multi_net (
  # From firewall
  $action      = undef,
  $chain       = undef,
  $iniface     = undef,
  $port        = undef,
  $proto       = undef,
  # Custom
  $rule_name   = $title,
  $source_nets = undef,
) {
  validate_string($rule_name)

  if ! is_array($source_nets) {
    fail('This provider should only be used for multiple source_nets.')
  }
  $firewall_rule_hashes = prepare_firewall_rules($source_nets, $rule_name,
    $action, $chain, $port, $proto)

  create_resources('firewall', $firewall_rule_hashes)
}

