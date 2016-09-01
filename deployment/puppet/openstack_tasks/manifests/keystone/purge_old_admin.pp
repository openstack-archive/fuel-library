class openstack_tasks::keystone::purge_old_admin {

  notice('MODULAR: keystone/purge_old_admin.pp')

  $old_access_hash = hiera_hash('old_access', {})
  $access_hash     = hiera_hash('access', {})

  if !empty($old_access_hash) {
    $old_admin_user = $old_access_hash['user']

    if $old_admin_user != $access_hash['user'] {
      keystone_user { $old_admin_user:
        ensure   => absent,
      }
    }
  }
}
