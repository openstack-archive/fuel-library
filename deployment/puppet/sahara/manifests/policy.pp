# == Class: sahara::policy
#
# Configure the sahara policies
#
# === Parameters
#
# [*policies*]
#   (optional) Set of policies to configure for sahara
#   Example :
#     {
#       'sahara-context_is_admin' => {
#         'key' => 'context_is_admin',
#         'value' => 'true'
#        },
#        'sahara-default' => {
#          'key' => 'default',
#          'value' => 'rule:admin_or_owner'
#        }
#     }
#   Defaults to empty hash.
#
# [*policy_path*]
#   (optional) Path to the sahara policy.json file
#   Defaults to /etc/sahara/policy.json
#
class sahara::policy (
  $policies    = {},
  $policy_path = '/etc/sahara/policy.json',
) {

  validate_hash($policies)

  Openstacklib::Policy::Base {
    file_path => $policy_path,
  }

  create_resources('openstacklib::policy::base', $policies)

}
