# == Class: glance::policy
#
# Configure the glance policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for glance
#   Example :
#     {
#       'glance-context_is_admin' => {
#         'key' => 'context_is_admin',
#         'value' => 'true'
#       },
#       'glance-default' => {
#         'key' => 'default',
#         'value' => 'rule:admin_or_owner'
#       }
#     }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the glance policy.json file
#   Defaults to /etc/glance/policy.json
#
class glance::policy (
  $policies    = {},
  $policy_path = '/etc/glance/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
