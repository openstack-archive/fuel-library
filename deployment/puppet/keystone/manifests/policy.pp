# == Class: keystone::policy
#
# Configure the keystone policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for keystone
#   Example :
#     {
#       'keystone-context_is_admin' => {
#         'key' => 'context_is_admin',
#         'value' => 'true'
#       },
#       'keystone-default' => {
#         'key' => 'default',
#         'value' => 'rule:admin_or_owner'
#       }
#     }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the nova policy.json file
#   Defaults to /etc/keystone/policy.json
#
class keystone::policy (
  $policies    = {},
  $policy_path = '/etc/keystone/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
