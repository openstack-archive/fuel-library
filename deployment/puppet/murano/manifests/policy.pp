# == Class: murano::policy
#
# Configure the murano policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for murano
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the murano policy.json file
#   Defaults to /etc/murano/policy.json
#
class murano::policy (
  $policies    = {},
  $policy_path = '/etc/murano/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
