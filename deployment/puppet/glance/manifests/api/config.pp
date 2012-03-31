#
# Can be used to specify configuration
# sections in glance-api.conf
#
# It will assume that the config
#
#
define glance::api::config(
  $config    = {},
  $file_name = regsubst($name, ':', '_', 'G'),
  $content   = template("glance/api/${name}.erb"),
  $order     = undef
) {
  concat::fragment { $name:
    target  => '/etc/glance/glance-api.conf',
    content => $content,
    order   => $order,
  }
}

