# == Class: cinder::policy
#
# Configure the cinder policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for cinder
#   Example : { 'cinder-context_is_admin' => {'context_is_admin' => 'true'}, 'cinder-default' => {'default' => 'rule:admin_or_owner'} }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the cinder policy.json file
#   Defaults to /etc/cinder/policy.json
#
class cinder::policy (
  $policies    = {},
  $policy_path = '/etc/cinder/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
