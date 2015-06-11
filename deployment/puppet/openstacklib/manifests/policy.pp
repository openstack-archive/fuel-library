# == Class: openstacklib::policies
#
# This resource is an helper to call the policy definition
#
# == Parameters:
#
#  [*policies*]
#    Hash of policies one would like to set to specific values
#    hash; optional
#
class openstacklib::policy (
  $policies = {},
) {

  validate_hash($policies)

  create_resources('openstacklib::policy::base', $policies)

}
