class openstack_tasks::keystone::purge_old_admin {

  notice('MODULAR: keystone/purge_old_admin.pp')

  $access_hash    = hiera_hash('old_access', {})

  if !empty($access_hash) {
    $admin_user     = $access_hash['user']
    $admin_email    = $access_hash['email']
    $admin_password = $access_hash['password']

    keystone_user { $admin_user:
      ensure   => absent,
      email    => $admin_email,
      password => $admin_password,
    }
  }
}
