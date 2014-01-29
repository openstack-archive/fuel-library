class nailgun::keystone (
  $public_address           = '127.0.0.1',
  $admin_address            = '127.0.0.1',
  $internal_address         = '127.0.0.1',

  $db_host                  = '127.0.0.1',
  $db_port                  = '5432',
  $db_protocol              = 'postgresql',
  $db_user                  = 'keystone',
  $db_password              = 'keystone',
  $db_name                  = 'keystone',

  $admin_token              = 'ADMIN',
  $admin_email              = 'admin@localhost',
  $admin_user               = 'admin',
  $admin_password           = 'admin',
  $admin_tenant             = 'admin',
) {

  class { '::keystone':
    admin_token    => $admin_token,
    sql_connection => "${db_protocol}://${$db_user}:${db_password}@${db_host}:${db_port}/${db_name}",
  }

  class { 'keystone::roles::admin':
    admin        => $admin_user,
    email        => $admin_email,
    password     => $admin_password,
    admin_tenant => $admin_tenant,
  }

  class { 'keystone::endpoint':
    public_address   => $public_address,
    admin_address    => $admin_address,
    internal_address => $internal_address,
  }

}
