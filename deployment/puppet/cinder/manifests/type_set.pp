# ==Define: cinder::type_set
#
# Assigns keys after the volume type is set.
#
# === Parameters
#
# [*os_password*]
#   (required) The keystone tenant:username password.
#
# [*type*]
#   (required) Accepts single name of type to set.
#
# [*key*]
#   (required) the key name that we are setting the value for.
#
# [*os_tenant_name*]
#   (optional) The keystone tenant name. Defaults to 'admin'.
#
# [*os_username*]
#   (optional) The keystone user name. Defaults to 'admin.
#
# [*os_auth_url*]
#   (optional) The keystone auth url. Defaults to 'http://127.0.0.1:5000/v2.0/'.
#
# Author: Andrew Woodward <awoodward@mirantis.com>


define cinder::type_set (
  $type,
  $key,
  $os_password,
  $os_tenant_name = 'admin',
  $os_username    = 'admin',
  $os_auth_url    = 'http://127.0.0.1:5000/v2.0/',
  ) {

# TODO: (xarses) This should be moved to a ruby provider so that among other
#   reasons, the credential discovery magic can occur like in neutron.

  exec {"cinder type-key ${type} set ${key}=${name}":
    path        => '/usr/bin',
    command     => "cinder type-key ${type} set ${key}=${name}",
    environment => [
      "OS_TENANT_NAME=${os_tenant_name}",
      "OS_USERNAME=${os_username}",
      "OS_PASSWORD=${os_password}",
      "OS_AUTH_URL=${os_auth_url}",
    ],
    require     => Package['python-cinderclient']
  }
}
