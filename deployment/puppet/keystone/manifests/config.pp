#
# Can be used to specify configuration
# sections in keystone
#
# It will assume that the config
#
#
define keystone::config(
  $config    = {},
  $content   = template("keystone/${name}.erb"),
  $order     = undef
) {
  concat::fragment { "kestone-${name}":
    target  => '/etc/keystone/keystone.conf',
    content => $content,
    order   => $order,
  }
}
