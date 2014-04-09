# == Class: nova::config
#
# This class is used to manage arbitrary Nova configurations.
#
# === Parameters
#
# [*nova_config*]
#   (optional) Allow configuration of arbitrary Nova configurations.
#   The value is an hash of nova_config resources. Example:
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#   In yaml format, Example:
#   nova_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class nova::config (
  $nova_config        = {},
  $nova_paste_api_ini = {},
) {

  validate_hash($nova_config)
  validate_hash($nova_paste_api_ini)

  create_resources('nova_config', $nova_config)
  create_resources('nova_paste_api_ini', $nova_paste_api_ini)
}
