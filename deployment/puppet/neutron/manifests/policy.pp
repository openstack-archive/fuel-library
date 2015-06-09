# == Class: neutron::policy
#
# Configure the neutron policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for neutron
#   Example :
#     {
#       'neutron-context_is_admin' => {
#         'key' => 'context_is_admin',
#         'value' => 'true'
#       },
#       'neutron-default' => {
#         'key' => 'default',
#         'value' => 'rule:admin_or_owner'
#       }
#     }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the neutron policy.json file
#   Defaults to /etc/neutron/policy.json
#
class neutron::policy (
  $policies    = {},
  $policy_path = '/etc/neutron/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
