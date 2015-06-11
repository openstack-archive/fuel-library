# == Definition: openstacklib::policy::base
#
# This resource configures the policy.json file for an OpenStack service
#
# == Parameters:
#
#  [*file_path*]
#    Path to the policy.json file
#    string; required
#
#  [*key*]
#    The key to replace the value for
#    string; required; the key to replace the value for
#
#  [*value*]
#    The value to set
#    string; optional; the value to set
#
define openstacklib::policy::base (
  $file_path,
  $key,
  $value = '',
) {

  augeas { "${file_path}-${key}-${value}" :
    lens    => 'Json.lns',
    incl    => $file_path,
    changes => "set dict/entry[*][.=\"${key}\"]/string ${value}"
  }

}
