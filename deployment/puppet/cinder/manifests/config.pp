# == Class: cinder::config
#
# This class is used to manage arbitrary cinder configurations.
#
# === Parameters
#
# [*xxx_config*]
#   (optional) Allow configuration of arbitrary cinder configurations.
#   The value is an hash of xxx_config resources. Example:
#   { 'DEFAULT/foo' => { value => 'fooValue'},
#     'DEFAULT/bar' => { value => 'barValue'}
#   }
#
#   In yaml format, Example:
#   xxx_config:
#     DEFAULT/foo:
#       value: fooValue
#     DEFAULT/bar:
#       value: barValue
#
# [**cinder_config**]
#   (optional) Allow configuration of cinder.conf configurations.
#
# [**api_paste_ini_config**]
#   (optional) Allow configuration of /etc/cinder/api-paste.ini configurations.
#
#   NOTE: The configuration MUST NOT be already handled by this module
#   or Puppet catalog compilation will fail with duplicate resources.
#
class cinder::config (
  $cinder_config         = {},
  $api_paste_ini_config  = {},
) {
  validate_hash($cinder_config)
  validate_hash($api_paste_ini_config)

  create_resources('cinder_config', $cinder_config)
  create_resources('cinder_api_paste_ini', $api_paste_ini_config)
}
