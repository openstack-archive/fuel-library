class openstack_tasks::openstack_controller::sync_db {
  notice('MODULAR: openstack_controller/sync_db.pp')
  include nova::db:sync_api
  include nova::db::sync
  exec { '/bin/true': }
  Exec['/bin/true'] ~>
  Exec<| title == 'nova-db-sync' or title == 'nova-db-sync-api' |> {
      tries     => '10',
      try_sleep => '5',
    }
}
