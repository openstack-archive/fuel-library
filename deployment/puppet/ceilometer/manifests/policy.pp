# == Class: ceilometer::policy
#
# Configure the ceilometer policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for ceilometer
#   Example : { 'ceilometer-context_is_admin' => {'context_is_admin' => 'true'}, 'ceilometer-default' => {'default' => 'rule:admin_or_owner'} }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the ceilometer policy.json file
#   Defaults to /etc/ceilometer/policy.json
#
class ceilometer::policy (
  $policies    = {},
  $policy_path = '/etc/ceilometer/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
