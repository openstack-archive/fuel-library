# == Class: ceilometer::config
#
# This class is used to manage arbitrary ceilometer configurations.
#
# === Parameters
#
# [*ceilometer_config*]
#   (optional) Allow configuration of ceilometer.conf.
#
#   The value is an hash of ceilometer_config resource. Example:
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#
#   In yaml format, Example:
#   ceilometer_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class ceilometer::config (
  $ceilometer_config         = {},
) {
  validate_hash($ceilometer_config)

  create_resources('ceilometer_config', $ceilometer_config)
}
